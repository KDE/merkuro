// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmanager.h"

#include "colorproxymodel.h"
#include "contactcollectionmodel.h"
#include "contactconfig.h"
#include "globalcontactmodel.h"
#include "merkuro_contact_debug.h"
#include "sortedcollectionproxymodel.h"
#include <Akonadi/AgentManager>
#include <Akonadi/Collection>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/CollectionStatistics>
#include <Akonadi/CollectionUtils>
#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EmailAddressSelectionModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityRightsFilterModel>
#include <Akonadi/ItemDeleteJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <Akonadi/SelectionProxyModel>
#include <KCheckableProxyModel>
#include <KConfigGroup>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KDescendantsProxyModel>
#include <KLocalizedString>
#include <KSelectionProxyModel>
#include <KSharedConfig>
#include <QBuffer>
#include <QItemSelectionModel>
#include <QPointer>

ContactManager::ContactManager(QObject *parent)
    : QObject(parent)
    , m_collectionTree(new Akonadi::EntityMimeTypeFilterModel(this))
{
    const auto contactModel = GlobalContactModel::instance()->model();
    connect(contactModel, &Akonadi::EntityTreeModel::errorOccurred, this, &ContactManager::errorOccurred);

    // Sidebar collection model
    m_collectionTree->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_collectionTree->setSourceModel(contactModel);
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
    m_colorProxy->setSourceModel(sortedModel);
    m_colorProxy->setObjectName(QLatin1StringView("Show contact colors"));
    m_colorProxy->setStandardCollectionId(contactConfig->lastUsedAddressBookCollection());
    connect(contactConfig, &ContactConfig::lastUsedAddressBookCollectionChanged, this, [this, contactConfig]() {
        m_colorProxy->setStandardCollectionId(contactConfig->lastUsedAddressBookCollection());
    });

    KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("kalendarrc"));
    m_collectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver(this);
    KConfigGroup selectionGroup = config->group(QStringLiteral("ContactCollectionSelection"));
    m_collectionSelectionModelStateSaver->setView(nullptr);
    m_collectionSelectionModelStateSaver->setSelectionModel(m_checkableProxyModel->selectionModel());
    m_collectionSelectionModelStateSaver->restoreState(selectionGroup);
    connect(m_checkableProxyModel->selectionModel(), &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &, const QItemSelection &) {
        saveState();
    });

    // List of contacts for the main contact view
    auto selectionProxyModel = new Akonadi::SelectionProxyModel(m_checkableProxyModel->selectionModel(), this);
    selectionProxyModel->setSourceModel(GlobalContactModel::instance()->model());
    selectionProxyModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    auto flatModel = new KDescendantsProxyModel(this);
    flatModel->setSourceModel(selectionProxyModel);

    auto entityMimeTypeFilterModel = new Akonadi::EntityMimeTypeFilterModel(this);
    entityMimeTypeFilterModel->setSourceModel(flatModel);
    entityMimeTypeFilterModel->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
    entityMimeTypeFilterModel->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);

    m_filteredContacts = new QSortFilterProxyModel(this);
    m_filteredContacts->setSourceModel(entityMimeTypeFilterModel);
    m_filteredContacts->setSortLocaleAware(true);
    m_filteredContacts->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->setFilterCaseSensitivity(Qt::CaseInsensitive);
    m_filteredContacts->sort(0);
}

ContactManager::~ContactManager()
{
    saveState();
}

void ContactManager::saveState() const
{
    Akonadi::ETMViewStateSaver treeStateSaver;
    KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("kalendarrc"));
    KConfigGroup group = config->group(QStringLiteral("ContactCollectionSelection"));
    treeStateSaver.setView(nullptr);
    treeStateSaver.setSelectionModel(m_checkableProxyModel->selectionModel());
    treeStateSaver.saveState(group);
}

QAbstractItemModel *ContactManager::contactCollections() const
{
    return m_colorProxy;
}

QAbstractItemModel *ContactManager::filteredContacts() const
{
    return m_filteredContacts;
}

Akonadi::Item ContactManager::getItem(qint64 itemId)
{
    Akonadi::Item item(itemId);

    return item;
}

void ContactManager::deleteItem(const Akonadi::Item &item)
{
    new Akonadi::ItemDeleteJob(item);
}

void ContactManager::updateAllCollections()
{
    const auto collections = contactCollections();
    for (int i = 0, count = collections->rowCount(); i < count; i++) {
        auto collection = collections->data(collections->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}

void ContactManager::updateCollection(const Akonadi::Collection &collection)
{
    Akonadi::AgentManager::self()->synchronizeCollection(collection, false);
}

void ContactManager::deleteCollection(const Akonadi::Collection &collection)
{
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // deletes contents
        auto job = new Akonadi::CollectionDeleteJob(collection, this);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(MERKURO_CONTACT_LOG) << "Error occurred deleting collection: " << job->errorString();
            }
        });
        return;
    }
    // deletes the agent, not the contents
    const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

void ContactManager::editCollection(const Akonadi::Collection &collection)
{
    // TODO: Reimplement this dialog in QML
    QPointer<Akonadi::CollectionPropertiesDialog> dlg = new Akonadi::CollectionPropertiesDialog(collection);
    dlg->setWindowTitle(i18nc("@title:window", "Properties of Address Book %1", collection.name()));
    dlg->show();
}

QVariantMap ContactManager::getCollectionDetails(const Akonadi::Collection &collection)
{
    QVariantMap collectionDetails;

    collectionDetails[QLatin1StringView("id")] = collection.id();
    collectionDetails[QLatin1StringView("name")] = collection.name();
    collectionDetails[QLatin1StringView("displayName")] = collection.displayName();
    collectionDetails[QLatin1StringView("color")] = m_colorProxy->color(collection.id());
    collectionDetails[QLatin1StringView("count")] = collection.statistics().count();
    collectionDetails[QLatin1StringView("isResource")] = Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QLatin1StringView("resource")] = collection.resource();
    collectionDetails[QLatin1StringView("readOnly")] = collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    collectionDetails[QLatin1StringView("canChange")] = collection.rights().testFlag(Akonadi::Collection::CanChangeCollection);
    collectionDetails[QLatin1StringView("canCreate")] = collection.rights().testFlag(Akonadi::Collection::CanCreateCollection);
    collectionDetails[QLatin1StringView("canDelete")] =
        collection.rights().testFlag(Akonadi::Collection::CanDeleteCollection) && !Akonadi::CollectionUtils::isResource(collection);

    return collectionDetails;
}

void ContactManager::setCollectionColor(Akonadi::Collection collection, const QColor &color)
{
    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);
    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [this, collection, color](KJob *job) {
        if (job->error()) {
            qCWarning(MERKURO_CONTACT_LOG) << "Error occurred modifying collection color: " << job->errorString();
        } else {
            m_colorProxy->setColor(collection.id(), color);
        }
    });
}

#include "moc_contactmanager.cpp"
