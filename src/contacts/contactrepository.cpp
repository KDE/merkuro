// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactrepository.h"

#include "birthdaycalendar.h"
#include "contactcollectionmodel.h"
#include "contactconfig.h"
#include "contactlistproxymodel.h"
#include "sortedcollectionproxymodel.h"
#include <Akonadi/ChangeRecorder>
#include <Akonadi/Collection>
#include <Akonadi/ColorProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EntityDisplayAttribute>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/SelectionProxyModel>
#include <Akonadi/Session>
#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KDescendantsProxyModel>
#include <KSelectionProxyModel>
#include <KSharedConfig>
#include <QItemSelectionModel>

using namespace Qt::Literals::StringLiterals;

namespace
{
void migrateCollectionSelection()
{
    const auto oldConfig = KSharedConfig::openConfig(u"kalendarrc"_s);
    const auto newConfig = KSharedConfig::openConfig(u"merkurocontactrc"_s);

    const auto groupName = u"ContactCollectionSelection"_s;
    if (!oldConfig->hasGroup(groupName) || newConfig->hasGroup(groupName)) {
        return;
    }

    const KConfigGroup oldGroup(oldConfig, groupName);
    KConfigGroup newGroup(newConfig, groupName);
    oldGroup.copyTo(&newGroup);
    oldConfig->deleteGroup(groupName);

    newConfig->sync();
    oldConfig->sync();
}
}

ContactRepository::ContactRepository(QObject *parent)
    : QObject(parent)
    , m_session(new Akonadi::Session("KAddressBook::ContactSession"))
    , m_monitor(new Akonadi::ChangeRecorder)
    , m_contactModel(new Akonadi::ContactsTreeModel(m_monitor))
    , m_collectionTree(new Akonadi::EntityMimeTypeFilterModel(this))
{
    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload(true);
    scope.fetchAttribute<Akonadi::EntityDisplayAttribute>();

    m_monitor->setSession(m_session);
    m_monitor->fetchCollection(true);
    m_monitor->setItemFetchScope(scope);
    m_monitor->setCollectionMonitored(Akonadi::Collection::root());
    m_monitor->setMimeTypeMonitored(KContacts::Addressee::mimeType(), true);
    m_monitor->setMimeTypeMonitored(KContacts::ContactGroup::mimeType(), true);

    connect(m_contactModel, &Akonadi::EntityTreeModel::errorOccurred, this, &ContactRepository::errorOccurred);

    m_collectionTree->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_collectionTree->setSourceModel(m_contactModel);
    m_collectionTree->addMimeTypeInclusionFilter(Akonadi::Collection::mimeType());
    m_collectionTree->setHeaderGroup(Akonadi::EntityTreeModel::CollectionTreeHeaders);

    m_collectionSelectionModel = new QItemSelectionModel(m_collectionTree);
    m_checkableProxyModel = new ContactCollectionModel(this);
    m_checkableProxyModel->setSelectionModel(m_collectionSelectionModel);
    m_checkableProxyModel->setSourceModel(m_collectionTree);

    auto contactConfig = ContactConfig::self();
    contactConfig->lastUsedAddressBookCollection();

    auto sortedModel = new SortedCollectionProxModel(this);
    sortedModel->setObjectName(QLatin1StringView("Sort collection"));
    sortedModel->setSourceModel(m_checkableProxyModel);
    sortedModel->addMimeTypeFilter(KContacts::Addressee::mimeType());
    sortedModel->addMimeTypeFilter(KContacts::ContactGroup::mimeType());
    sortedModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    sortedModel->sort(0, Qt::AscendingOrder);

    m_colorProxy = new ColorProxyModel(this);
    m_colorProxy->addMimeTypeFilters({
        "text/calendar"_L1,
        "application/x-vnd.akonadi.calendar.event"_L1,
        "application/x-vnd.akonadi.calendar.todo"_L1,
        "text/directory"_L1,
        "inode/directory"_L1,
        "application/x-vnd.kde.contactgroup"_L1,
        "application/x-vnd.akonadi.calendar.journal"_L1,
    });
    m_colorProxy->setSourceModel(sortedModel);
    m_colorProxy->setObjectName(QLatin1StringView("Show contact colors"));
    m_colorProxy->setStandardCollectionId(contactConfig->lastUsedAddressBookCollection());
    connect(contactConfig, &ContactConfig::lastUsedAddressBookCollectionChanged, this, [this, contactConfig]() {
        m_colorProxy->setStandardCollectionId(contactConfig->lastUsedAddressBookCollection());
    });

    migrateCollectionSelection();
    const auto config = KSharedConfig::openConfig(u"merkurocontactrc"_s);
    m_collectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver();
    KConfigGroup selectionGroup = config->group(u"ContactCollectionSelection"_s);
    m_collectionSelectionModelStateSaver->setView(nullptr);
    m_collectionSelectionModelStateSaver->setSelectionModel(m_checkableProxyModel->selectionModel());
    m_collectionSelectionModelStateSaver->restoreState(selectionGroup);
    connect(m_checkableProxyModel->selectionModel(),
            &QItemSelectionModel::selectionChanged,
            this,
            [this](const QItemSelection &selected, const QItemSelection &) {
                const auto selectedIndexes = m_collectionSelectionModel->selectedIndexes();
                if (selectedIndexes.size() > 1) {
                    const auto newlySelected = selected.indexes();
                    m_collectionSelectionModel->select(newlySelected.isEmpty() ? selectedIndexes.constFirst() : newlySelected.constLast(),
                                                       QItemSelectionModel::ClearAndSelect);
                    return;
                }
                saveState();
            });
    const auto restoredSelection = m_collectionSelectionModel->selectedIndexes();
    if (restoredSelection.size() > 1) {
        m_collectionSelectionModel->select(restoredSelection.constFirst(), QItemSelectionModel::ClearAndSelect);
    }

    m_selectionProxyModel = new Akonadi::SelectionProxyModel(m_checkableProxyModel->selectionModel());
    m_selectionProxyModel->setSourceModel(m_contactModel);
    m_selectionProxyModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    auto flatModel = new KDescendantsProxyModel(this);
    flatModel->setSourceModel(m_selectionProxyModel);

    auto entityMimeTypeFilterModel = new Akonadi::EntityMimeTypeFilterModel(this);
    entityMimeTypeFilterModel->setSourceModel(flatModel);
    entityMimeTypeFilterModel->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
    entityMimeTypeFilterModel->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);
    m_selectedContacts = entityMimeTypeFilterModel;

    auto allFlatModel = new KDescendantsProxyModel(this);
    allFlatModel->setSourceModel(m_contactModel);

    auto allItemModel = new Akonadi::EntityMimeTypeFilterModel(this);
    allItemModel->setSourceModel(allFlatModel);
    allItemModel->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
    allItemModel->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);
    m_allContacts = allItemModel;

    m_filteredContacts = new ContactListProxyModel(this);
    m_filteredContacts->setSourceModel(m_selectedContacts);
    m_filteredContacts->setSortLocaleAware(true);
    m_filteredContacts->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->sort(0);
}

ContactRepository::~ContactRepository()
{
    saveState();
    delete m_selectionProxyModel;
    delete m_contactModel;
    delete m_monitor;
    delete m_session;
}

void ContactRepository::saveState() const
{
    Akonadi::ETMViewStateSaver treeStateSaver;
    const auto config = KSharedConfig::openConfig(u"merkurocontactrc"_s);
    KConfigGroup group = config->group(u"ContactCollectionSelection"_s);
    treeStateSaver.setView(nullptr);
    treeStateSaver.setSelectionModel(m_checkableProxyModel->selectionModel());
    treeStateSaver.saveState(group);
}

QAbstractItemModel *ContactRepository::contactCollections() const
{
    return m_colorProxy;
}

QAbstractItemModel *ContactRepository::filteredContacts() const
{
    return m_filteredContacts;
}

bool ContactRepository::showBirthdays() const
{
    return m_showBirthdays;
}

void ContactRepository::setShowBirthdays(bool enabled)
{
    if (m_showBirthdays == enabled) {
        return;
    }

    m_showBirthdays = enabled;
    if (enabled) {
        m_collectionSelectionModel->clearSelection();
    }
    if (enabled && !m_birthdayCalendar) {
        m_birthdayCalendar = new BirthdayCalendar(this);
        connect(m_birthdayCalendar, &BirthdayCalendar::birthdaysChanged, this, [this]() {
            if (m_showBirthdays) {
                m_filteredContacts->setBirthdays(m_birthdayCalendar->birthdays());
            }
        });
    }

    m_filteredContacts->setSourceModel(enabled ? m_allContacts : m_selectedContacts);
    if (enabled) {
        m_filteredContacts->setBirthdays(m_birthdayCalendar->birthdays());
    }
    m_filteredContacts->setBirthdaysOnly(enabled);
}

qint64 ContactRepository::selectedCollectionId() const
{
    const auto selectedIndexes = m_collectionSelectionModel->selectedIndexes();
    if (selectedIndexes.isEmpty()) {
        return -1;
    }

    return selectedIndexes.constFirst().data(Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>().id();
}

QColor ContactRepository::collectionColor(qint64 collectionId) const
{
    return m_colorProxy->color(collectionId);
}

void ContactRepository::setCollectionColor(qint64 collectionId, const QColor &color)
{
    m_colorProxy->setColor(collectionId, color);
}

#include "moc_contactrepository.cpp"
