//  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
//  SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
//  SPDX-FileCopyrightText: 2003, 2004 Cornelius Schumacher <schumacher@kde.org>
//  SPDX-FileCopyrightText: 2003-2004 Reinhold Kainhofer <reinhold@kainhofer.com>
//  SPDX-FileCopyrightText: 2009 Sebastian Sauer <sebsauer@kdab.net>
//  SPDX-FileCopyrightText: 2010-2021 Laurent Montel <montel@kde.org>
//  SPDX-FileCopyrightText: 2012 Sérgio Martins <iamsergio@gmail.com>
//
//  SPDX-License-Identifier: GPL-2.0-or-later WITH LicenseRef-Qt-Commercial-exception-1.0

#include "calendarmanager.h"

// Akonadi
#include "merkuro_calendar_debug.h"

#include "models/todosortfilterproxymodel.h"
#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstanceModel>
#include <Akonadi/AgentManager>
#include <Akonadi/AttributeFactory>
#include <Akonadi/CachePolicy>
#include <Akonadi/Collection>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionIdentificationAttribute>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/CollectionUtils>
#include <Akonadi/Control>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EntityDisplayAttribute>
#include <Akonadi/EntityRightsFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/History>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemMoveJob>
#include <Akonadi/Monitor>
#include <KCheckableProxyModel>
#include <KDescendantsProxyModel>
#include <KLocalizedString>
#include <QApplication>

#include "colorproxymodel.h"
#include "incidencewrapper.h"
#include "sortedcollectionproxymodel.h"

using namespace Akonadi;
using namespace Qt::Literals::StringLiterals;
static Akonadi::EntityTreeModel *findEtm(QAbstractItemModel *model)
{
    QAbstractProxyModel *proxyModel = nullptr;
    while (model) {
        proxyModel = qobject_cast<QAbstractProxyModel *>(model);
        if (proxyModel && proxyModel->sourceModel()) {
            model = proxyModel->sourceModel();
        } else {
            break;
        }
    }
    return qobject_cast<Akonadi::EntityTreeModel *>(model);
}

/**
 * Automatically checks new calendar entries
 */
class NewCalendarChecker : public QObject
{
    Q_OBJECT
public:
    explicit NewCalendarChecker(QAbstractItemModel *model = nullptr)
        : QObject(model)
        , mCheckableProxy(model)
    {
        if (model) {
            connect(model, &QAbstractItemModel::rowsInserted, this, &NewCalendarChecker::onSourceRowsInserted);
        }
        qRegisterMetaType<QPersistentModelIndex>("QPersistentModelIndex");
    }

private Q_SLOTS:
    void onSourceRowsInserted(const QModelIndex &parent, int start, int end)
    {
        Akonadi::EntityTreeModel *etm = findEtm(mCheckableProxy);
        // Only check new collections and not during initial population
        if (!etm || !etm->isCollectionTreeFetched()) {
            return;
        }
        for (int i = start; i <= end; ++i) {
            // qCDebug(KORGANIZER_LOG) << "checking " << i << parent << mCheckableProxy->index(i, 0, parent).data().toString();
            const QModelIndex index = mCheckableProxy->index(i, 0, parent);
            QMetaObject::invokeMethod(this, "setCheckState", Qt::QueuedConnection, Q_ARG(QPersistentModelIndex, index));
        }
    }

    void setCheckState(const QPersistentModelIndex &index)
    {
        mCheckableProxy->setData(index, Qt::Checked, Qt::CheckStateRole);
        if (mCheckableProxy->hasChildren(index)) {
            onSourceRowsInserted(index, 0, mCheckableProxy->rowCount(index) - 1);
        }
    }

private:
    QAbstractItemModel *const mCheckableProxy;
};

class CollectionFilter : public QSortFilterProxyModel
{
public:
    explicit CollectionFilter(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        const Akonadi::Collection &col = sourceIndex.data(Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        const auto attr = col.attribute<Akonadi::CollectionIdentificationAttribute>();

        // We filter the user folders because we insert person nodes for user folders.
        if ((attr && attr->collectionNamespace().startsWith("usertoplevel")) || col.name().contains(QLatin1StringView("Other Users"))) {
            return false;
        }
        return true;
    }
};

CalendarManager::CalendarManager(QObject *parent)
    : QObject(parent)
    , m_calendar(nullptr)
    , m_config(new CalendarConfig(this))
{
    if (!Akonadi::Control::start()) {
        qApp->exit(-1);
        return;
    }

    auto colorProxy = new ColorProxyModel(this);
    colorProxy->setObjectName(QLatin1StringView("Show calendar colors"));
    colorProxy->setStandardCollectionId(m_config->lastUsedEventCollection());

    connect(m_config, &CalendarConfig::lastUsedEventCollectionChanged, this, [this, colorProxy]() {
        colorProxy->setStandardCollectionId(m_config->lastUsedEventCollection());
    });
    m_baseModel = colorProxy;

    // Hide collections that are not required
    auto collectionFilter = new CollectionFilter(this);
    collectionFilter->setSourceModel(colorProxy);

    m_calendar = QSharedPointer<Akonadi::ETMCalendar>::create(); // QSharedPointer
    setCollectionSelectionProxyModel(m_calendar->checkableProxyModel());
    connect(m_calendar->checkableProxyModel(), &KCheckableProxyModel::dataChanged, this, &CalendarManager::refreshEnabledTodoCollections);

    connect(m_calendar->entityTreeModel(), &Akonadi::EntityTreeModel::errorOccurred, this, &CalendarManager::errorOccurred);

    m_changer = m_calendar->incidenceChanger();
    m_changer->setHistoryEnabled(true);
    connect(m_changer->history(), &Akonadi::History::changed, this, &CalendarManager::undoRedoDataChanged);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    mCollectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver(); // not a leak
    KConfigGroup selectionGroup = config->group(u"GlobalCollectionSelection"_s);
    mCollectionSelectionModelStateSaver->setView(nullptr);
    mCollectionSelectionModelStateSaver->setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    mCollectionSelectionModelStateSaver->restoreState(selectionGroup);

    m_allCalendars = new Akonadi::CollectionFilterProxyModel(this);
    m_allCalendars->setSourceModel(collectionFilter);
    m_allCalendars->setExcludeVirtualCollections(true);

    // Filter it by mimetype again, to only keep
    // Kolab / Inbox / Calendar
    m_eventMimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(this);
    m_eventMimeTypeFilterModel->setSourceModel(collectionFilter);
    m_eventMimeTypeFilterModel->addMimeTypeFilter(u"application/x-vnd.akonadi.calendar.event"_s);

    // text/calendar mimetype includes todo cals
    m_todoMimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(this);
    m_todoMimeTypeFilterModel->setSourceModel(collectionFilter);
    m_todoMimeTypeFilterModel->addMimeTypeFilter(u"application/x-vnd.akonadi.calendar.todo"_s);
    m_todoMimeTypeFilterModel->setExcludeVirtualCollections(true);

    // Filter by access rights
    m_allCollectionsRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_allCollectionsRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_allCollectionsRightsFilterModel->setSourceModel(collectionFilter);

    m_eventRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_eventRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_eventRightsFilterModel->setSourceModel(m_eventMimeTypeFilterModel);

    m_todoRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_todoRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_todoRightsFilterModel->setSourceModel(m_todoMimeTypeFilterModel);

    // Model for todo via collection picker
    m_todoViewCollectionModel = new SortedCollectionProxModel(this);
    m_todoViewCollectionModel->setSourceModel(collectionFilter);
    m_todoViewCollectionModel->addMimeTypeFilter(u"application/x-vnd.akonadi.calendar.todo"_s);
    m_todoViewCollectionModel->setExcludeVirtualCollections(true);
    m_todoViewCollectionModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_todoViewCollectionModel->sort(0, Qt::AscendingOrder);

    // Model for the mainDrawer
    m_viewCollectionModel = new SortedCollectionProxModel(this);
    m_viewCollectionModel->setSourceModel(collectionFilter);
    m_viewCollectionModel->addMimeTypeFilter(u"application/x-vnd.akonadi.calendar.event"_s);
    m_viewCollectionModel->addMimeTypeFilter(u"application/x-vnd.akonadi.calendar.todo"_s);
    m_viewCollectionModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_viewCollectionModel->sort(0, Qt::AscendingOrder);

    m_flatCollectionTreeModel = new KDescendantsProxyModel(this);
    m_flatCollectionTreeModel->setSourceModel(m_viewCollectionModel);
    m_flatCollectionTreeModel->setExpandsByDefault(true);

    auto refreshColors = [this, colorProxy]() {
        for (auto i = 0; i < m_flatCollectionTreeModel->rowCount(); i++) {
            auto idx = m_flatCollectionTreeModel->index(i, 0, {});
            colorProxy->getCollectionColor(Akonadi::CollectionUtils::fromIndex(idx));
        }
    };
    connect(m_flatCollectionTreeModel, &QSortFilterProxyModel::rowsInserted, this, refreshColors);

    KConfigGroup rColorsConfig(config, u"Resources Colors"_s);
    m_colorWatcher = KConfigWatcher::create(config);
    connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &CalendarManager::collectionColorsChanged);

    connect(m_calendar.data(), &Akonadi::ETMCalendar::calendarChanged, this, &CalendarManager::calendarChanged);
}

CalendarManager::~CalendarManager()
{
    save();
    // delete mCollectionSelectionModelStateSaver;
}

void CalendarManager::save()
{
    Akonadi::ETMViewStateSaver treeStateSaver;
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup group = config->group(u"GlobalCollectionSelection"_s);
    treeStateSaver.setView(nullptr);
    treeStateSaver.setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    treeStateSaver.saveState(group);

    config->sync();
}

void CalendarManager::delayedInit()
{
    Q_EMIT loadingChanged();
}

QAbstractProxyModel *CalendarManager::collections()
{
    return static_cast<QAbstractProxyModel *>(m_flatCollectionTreeModel->sourceModel());
}

QAbstractItemModel *CalendarManager::todoCollections()
{
    return m_todoViewCollectionModel;
}

QAbstractItemModel *CalendarManager::viewCollections()
{
    return m_viewCollectionModel;
}

QList<qint64> CalendarManager::enabledTodoCollections()
{
    return m_enabledTodoCollections;
}

void CalendarManager::refreshEnabledTodoCollections()
{
    m_enabledTodoCollections.clear();
    const auto selectedIndexes = m_calendar->checkableProxyModel()->selectionModel()->selectedIndexes();
    for (auto selectedIndex : selectedIndexes) {
        auto collection = selectedIndex.data(Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        if (collection.contentMimeTypes().contains(u"application/x-vnd.akonadi.calendar.todo"_s)) {
            m_enabledTodoCollections.append(collection.id());
        }
    }

    Q_EMIT enabledTodoCollectionsChanged();
}

bool CalendarManager::loading() const
{
    return m_calendar->isLoading();
}

void CalendarManager::setCollectionSelectionProxyModel(KCheckableProxyModel *m)
{
    if (m_selectionProxyModel == m) {
        return;
    }

    m_selectionProxyModel = m;
    if (!m_selectionProxyModel) {
        return;
    }

    new NewCalendarChecker(m);
    m_baseModel->setSourceModel(m_selectionProxyModel);
}

KCheckableProxyModel *CalendarManager::collectionSelectionProxyModel() const
{
    return m_selectionProxyModel;
}

Akonadi::ETMCalendar::Ptr CalendarManager::calendar() const
{
    return m_calendar;
}

Akonadi::IncidenceChanger *CalendarManager::incidenceChanger() const
{
    return m_changer;
}

Akonadi::CollectionFilterProxyModel *CalendarManager::allCalendars()
{
    return m_allCalendars;
}

qint64 CalendarManager::defaultCalendarId(IncidenceWrapper *incidenceWrapper)
{
    // Checks if default collection accepts this type of incidence
    auto mimeType = incidenceWrapper->incidencePtr()->mimeType();
    Akonadi::Collection collection = m_calendar->collection(m_config->lastUsedEventCollection());
    bool supportsMimeType = collection.contentMimeTypes().contains(mimeType) || mimeType == QLatin1StringView("");
    bool hasRights = collection.rights() & Akonadi::Collection::CanCreateItem;
    if (collection.isValid() && supportsMimeType && hasRights) {
        return collection.id();
    }

    // Should add last used collection by mimetype somewhere.

    // Searches for first collection that will accept this incidence
    for (int i = 0; i < m_allCalendars->rowCount(); i++) {
        QModelIndex idx = m_allCalendars->index(i, 0);
        collection = idx.data(Akonadi::EntityTreeModel::Roles::CollectionRole).value<Akonadi::Collection>();
        supportsMimeType = collection.contentMimeTypes().contains(mimeType) || mimeType == QLatin1StringView("");
        hasRights = collection.rights() & Akonadi::Collection::CanCreateItem;
        if (collection.isValid() && supportsMimeType && hasRights) {
            return collection.id();
        }
    }

    return -1;
}

QVariant CalendarManager::getIncidenceSubclassed(KCalendarCore::Incidence::Ptr incidencePtr)
{
    switch (incidencePtr->type()) {
    case (KCalendarCore::IncidenceBase::TypeEvent):
        return QVariant::fromValue(m_calendar->event(incidencePtr->instanceIdentifier()));
        break;
    case (KCalendarCore::IncidenceBase::TypeTodo):
        return QVariant::fromValue(m_calendar->todo(incidencePtr->instanceIdentifier()));
        break;
    case (KCalendarCore::IncidenceBase::TypeJournal):
        return QVariant::fromValue(m_calendar->journal(incidencePtr->instanceIdentifier()));
        break;
    default:
        return QVariant::fromValue(incidencePtr);
        break;
    }
}

UndoRedoData CalendarManager::undoRedoData()
{
    if (!m_changer || !m_changer->history()) {
        return {
            false,
            false,
            QString(),
            QString(),
        };
    }
    return {
        m_changer->history()->undoAvailable(),
        m_changer->history()->redoAvailable(),
        m_changer->history()->nextUndoDescription(),
        m_changer->history()->nextRedoDescription(),
    };
}

Akonadi::Item CalendarManager::incidenceItem(KCalendarCore::Incidence::Ptr incidence) const
{
    return m_calendar->item(incidence);
}

Akonadi::Item CalendarManager::incidenceItem(const QString &uid) const
{
    return incidenceItem(m_calendar->incidence(uid));
}

KCalendarCore::Incidence::List CalendarManager::childIncidences(const QString &uid) const
{
    return m_calendar->childIncidences(uid);
}

void CalendarManager::addIncidence(IncidenceWrapper *incidenceWrapper)
{
    if (incidenceWrapper->collectionId() < 0) {
        const auto sharedConfig = KSharedConfig::openConfig();
        const auto editorConfigSection = sharedConfig->group(u"Editor"_s);

        const auto lastUsedCollectionType =
            incidenceWrapper->incidenceType() == KCalendarCore::IncidenceBase::TypeTodo ? u"lastUsedTodoCollection"_s : u"lastUsedEventCollection"_s;
        const auto lastUsedCollectionId = editorConfigSection.readEntry(lastUsedCollectionType, -1);

        if (lastUsedCollectionId > -1) {
            incidenceWrapper->setCollectionId(lastUsedCollectionId);
        }
    }

    Akonadi::Collection collection(incidenceWrapper->collectionId());

    switch (incidenceWrapper->incidencePtr()->type()) {
    case (KCalendarCore::IncidenceBase::TypeEvent): {
        KCalendarCore::Event::Ptr event = incidenceWrapper->incidencePtr().staticCast<KCalendarCore::Event>();
        m_changer->createIncidence(event, collection);
        break;
    }
    case (KCalendarCore::IncidenceBase::TypeTodo): {
        KCalendarCore::Todo::Ptr todo = incidenceWrapper->incidencePtr().staticCast<KCalendarCore::Todo>();
        m_changer->createIncidence(todo, collection);
        break;
    }
    default:
        m_changer->createIncidence(KCalendarCore::Incidence::Ptr(incidenceWrapper->incidencePtr()->clone()), collection);
        break;
    }
    // This will fritz if you don't choose a valid *calendar*
}

// Replicates IncidenceDialogPrivate::save
void CalendarManager::editIncidence(IncidenceWrapper *incidenceWrapper)
{
    // We need to use the incidenceChanger manually to get the change recorded in the history
    // For undo/redo to work properly we need to change the ownership of the incidence pointers
    KCalendarCore::Incidence::Ptr changedIncidence(incidenceWrapper->incidencePtr()->clone());
    KCalendarCore::Incidence::Ptr originalPayload(incidenceWrapper->originalIncidencePtr()->clone());

    Akonadi::Item modifiedItem = m_calendar->item(changedIncidence->instanceIdentifier());
    modifiedItem.setPayload<KCalendarCore::Incidence::Ptr>(changedIncidence);

    m_changer->modifyIncidence(modifiedItem, originalPayload);

    if (!incidenceWrapper->collectionId() || incidenceWrapper->collectionId() < 0 || modifiedItem.parentCollection().id() == incidenceWrapper->collectionId()) {
        return;
    }

    changeIncidenceCollection(modifiedItem, incidenceWrapper->collectionId());
}

void CalendarManager::updateIncidenceDates(IncidenceWrapper *incidenceWrapper, int startOffset, int endOffset, int occurrences, const QDateTime &occurrenceDate)
{ // start and end offsets are in msecs

    Akonadi::Item item = m_calendar->item(incidenceWrapper->incidencePtr());
    item.setPayload(incidenceWrapper->incidencePtr());

    auto setNewDates = [&](KCalendarCore::Incidence::Ptr incidence) {
        if (incidence->type() == KCalendarCore::Incidence::TypeTodo) {
            // For to-dos endOffset is ignored because it will always be == to startOffset because we only
            // support moving to-dos, not resizing them. There are no multi-day to-dos.
            // Lets just call it offset to reduce confusion.
            const int offset = startOffset;

            KCalendarCore::Todo::Ptr todo = incidence.staticCast<KCalendarCore::Todo>();
            QDateTime due = todo->dtDue();
            QDateTime start = todo->dtStart();
            if (due.isValid()) { // Due has priority over start.
                // We will only move the due date, unlike events where we move both.
                due = due.addMSecs(offset);
                todo->setDtDue(due);

                if (start.isValid() && start > due) {
                    // Start can't be bigger than due.
                    todo->setDtStart(due);
                }
            } else if (start.isValid()) {
                // So we're displaying a to-do that doesn't have due date, only start...
                start = start.addMSecs(offset);
                todo->setDtStart(start);
            } else {
                // This never happens
                // qCWarning(CALENDARVIEW_LOG) << "Move what? uid:" << todo->uid() << "; summary=" << todo->summary();
            }
        } else {
            incidence->setDtStart(incidence->dtStart().addMSecs(startOffset));
            if (incidence->type() == KCalendarCore::Incidence::TypeEvent) {
                KCalendarCore::Event::Ptr event = incidence.staticCast<KCalendarCore::Event>();
                event->setDtEnd(event->dtEnd().addMSecs(endOffset));
            }
        }
    };

    if (incidenceWrapper->incidencePtr()->recurs()) {
        switch (occurrences) {
        case KCalUtils::RecurrenceActions::AllOccurrences: {
            // All occurrences
            KCalendarCore::Incidence::Ptr oldIncidence(incidenceWrapper->incidencePtr()->clone());
            setNewDates(incidenceWrapper->incidencePtr());
            qCDebug(MERKURO_CALENDAR_LOG) << incidenceWrapper->incidenceStart();
            m_changer->modifyIncidence(item, oldIncidence);
            break;
        }
        case KCalUtils::RecurrenceActions::SelectedOccurrence: // Just this occurrence
        case KCalUtils::RecurrenceActions::FutureOccurrences: { // All future occurrences
            const bool thisAndFuture = (occurrences == KCalUtils::RecurrenceActions::FutureOccurrences);
            auto tzedOccurrenceDate = occurrenceDate.toTimeZone(incidenceWrapper->incidenceStart().timeZone());
            KCalendarCore::Incidence::Ptr newIncidence(
                KCalendarCore::Calendar::createException(incidenceWrapper->incidencePtr(), tzedOccurrenceDate, thisAndFuture));

            if (newIncidence) {
                m_changer->startAtomicOperation(i18n("Move occurrence(s)"));
                setNewDates(newIncidence);
                m_changer->createIncidence(newIncidence, m_calendar->collection(incidenceWrapper->collectionId()));
                m_changer->endAtomicOperation();
            } else {
                qCDebug(MERKURO_CALENDAR_LOG) << i18n("Unable to add the exception item to the calendar. No change will be done.");
            }
            break;
        }
        }
    } else { // Doesn't recur
        KCalendarCore::Incidence::Ptr oldIncidence(incidenceWrapper->incidencePtr()->clone());
        setNewDates(incidenceWrapper->incidencePtr());
        m_changer->modifyIncidence(item, oldIncidence);
    }

    Q_EMIT updateIncidenceDatesCompleted();
}

bool CalendarManager::hasChildren(KCalendarCore::Incidence::Ptr incidence)
{
    return !m_calendar->childIncidences(incidence->uid()).isEmpty();
}

void CalendarManager::deleteAllChildren(KCalendarCore::Incidence::Ptr incidence)
{
    const auto allChildren = m_calendar->childIncidences(incidence->uid());

    for (const auto &child : allChildren) {
        if (!m_calendar->childIncidences(child->uid()).isEmpty()) {
            deleteAllChildren(child);
        }
    }

    for (const auto &child : allChildren) {
        m_calendar->deleteIncidence(child);
    }
}

void CalendarManager::deleteIncidence(KCalendarCore::Incidence::Ptr incidence, bool deleteChildren)
{
    const auto directChildren = m_calendar->childIncidences(incidence->uid());

    if (!directChildren.isEmpty()) {
        if (deleteChildren) {
            m_changer->startAtomicOperation(i18n("Delete task and its sub-tasks"));
            deleteAllChildren(incidence);
        } else {
            m_changer->startAtomicOperation(i18n("Delete task and make sub-tasks independent"));
            for (const auto &child : directChildren) {
                const auto instances = m_calendar->instances(child);
                for (const auto &instance : instances) {
                    KCalendarCore::Incidence::Ptr oldInstance(instance->clone());
                    instance->setRelatedTo(QString());
                    m_changer->modifyIncidence(m_calendar->item(instance), oldInstance);
                }

                KCalendarCore::Incidence::Ptr oldInc(child->clone());
                child->setRelatedTo(QString());
                m_changer->modifyIncidence(m_calendar->item(child), oldInc);
            }
        }

        m_calendar->deleteIncidence(incidence);
        m_changer->endAtomicOperation();
        return;
    }

    m_calendar->deleteIncidence(incidence);
}

void CalendarManager::changeIncidenceCollection(KCalendarCore::Incidence::Ptr incidence, qint64 collectionId)
{
    KCalendarCore::Incidence::Ptr incidenceClone(incidence->clone());
    Akonadi::Item modifiedItem = m_calendar->item(incidence->instanceIdentifier());
    modifiedItem.setPayload<KCalendarCore::Incidence::Ptr>(incidenceClone);

    if (modifiedItem.parentCollection().id() != collectionId) {
        changeIncidenceCollection(modifiedItem, collectionId);
    }
}

void CalendarManager::changeIncidenceCollection(Akonadi::Item item, qint64 collectionId)
{
    if (item.parentCollection().id() == collectionId) {
        return;
    }

    Q_ASSERT(item.hasPayload<KCalendarCore::Incidence::Ptr>());

    Akonadi::Collection newCollection(collectionId);
    item.setParentCollection(newCollection);

    auto job = new Akonadi::ItemMoveJob(item, newCollection);
    // Add some type of check here?
    connect(job, &KJob::result, job, [this, job, item, collectionId]() {
        qCDebug(MERKURO_CALENDAR_LOG) << job->error();

        if (!job->error()) {
            const auto allChildren = m_calendar->childIncidences(item.id());
            for (const auto &child : allChildren) {
                changeIncidenceCollection(m_calendar->item(child), collectionId);
            }

            auto parent = item.payload<KCalendarCore::Incidence::Ptr>()->relatedTo();
            if (!parent.isEmpty()) {
                changeIncidenceCollection(m_calendar->item(parent), collectionId);
            }
        }
    });
}

QVariantMap CalendarManager::getCollectionDetails(QVariant collectionId)
{
    QVariantMap collectionDetails;
    Akonadi::Collection collection = m_calendar->collection(collectionId.toInt());
    bool isFiltered = false;
    int allCalendarsRow = 0;

    for (int i = 0; i < m_allCalendars->rowCount(); i++) {
        if (m_allCalendars->data(m_allCalendars->index(i, 0), Akonadi::EntityTreeModel::CollectionIdRole).toInt() == collectionId) {
            isFiltered = !m_allCalendars->data(m_allCalendars->index(i, 0), Qt::CheckStateRole).toBool();
            allCalendarsRow = i;
            break;
        }
    }

    collectionDetails[QLatin1StringView("id")] = collection.id();
    collectionDetails[QLatin1StringView("name")] = collection.name();
    collectionDetails[QLatin1StringView("displayName")] = collection.displayName();
    collectionDetails[QLatin1StringView("color")] = m_baseModel->color(collection.id());
    collectionDetails[QLatin1StringView("count")] = collection.statistics().count();
    collectionDetails[QLatin1StringView("size")] = collection.statistics().size();
    collectionDetails[QLatin1StringView("isResource")] = Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QLatin1StringView("resource")] = collection.resource();
    collectionDetails[QLatin1StringView("readOnly")] = collection.rights().testFlag(Collection::ReadOnly);
    collectionDetails[QLatin1StringView("canChange")] = collection.rights().testFlag(Collection::CanChangeCollection);
    collectionDetails[QLatin1StringView("canDelete")] =
        collection.rights().testFlag(Collection::CanDeleteCollection) && !Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QLatin1StringView("isFiltered")] = isFiltered;
    collectionDetails[QLatin1StringView("allCalendarsRow")] = allCalendarsRow;

    return collectionDetails;
}

void CalendarManager::setCollectionColor(qint64 collectionId, const QColor &color)
{
    auto collection = m_calendar->collection(collectionId);
    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);
    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [this, collectionId, color](KJob *job) {
        if (job->error()) {
            qCWarning(MERKURO_CALENDAR_LOG) << "Error occurred modifying collection color: " << job->errorString();
        } else {
            m_baseModel->setColor(collectionId, color);
        }
    });
}

void CalendarManager::undoAction()
{
    m_changer->history()->undo();
}

void CalendarManager::redoAction()
{
    m_changer->history()->redo();
}

void CalendarManager::updateAllCollections()
{
    for (int i = 0; i < collections()->rowCount(); i++) {
        auto collection = collections()->data(collections()->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}

void CalendarManager::updateCollection(qint64 collectionId)
{
    auto collection = m_calendar->collection(collectionId);
    Akonadi::AgentManager::self()->synchronizeCollection(collection, false);
}

void CalendarManager::deleteCollection(qint64 collectionId)
{
    auto collection = m_calendar->collection(collectionId);
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // deletes contents
        auto job = new Akonadi::CollectionDeleteJob(collection, this);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(MERKURO_CALENDAR_LOG) << "Error occurred deleting collection: " << job->errorString();
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

void CalendarManager::toggleCollection(qint64 collectionId)
{
    const auto matches = m_calendar->checkableProxyModel()->match(m_calendar->checkableProxyModel()->index(0, 0),
                                                                  Akonadi::EntityTreeModel::CollectionIdRole,
                                                                  collectionId,
                                                                  1,
                                                                  Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);
    if (!matches.isEmpty()) {
        const auto collectionIndex = matches.first();
        const auto collectionChecked = collectionIndex.data(Qt::CheckStateRole).toInt() == Qt::Checked;
        const auto checkStateToSet = collectionChecked ? Qt::Unchecked : Qt::Checked;
        m_calendar->checkableProxyModel()->setData(collectionIndex, checkStateToSet, Qt::CheckStateRole);
    }
}

IncidenceWrapper *CalendarManager::createIncidenceWrapper()
{
    // Ownership is transferred to the qml engine
    return new IncidenceWrapper(this, nullptr);
}

Akonadi::Collection CalendarManager::getCollection(qint64 collectionId)
{
    qWarning() << "getting" << collectionId;
    return m_calendar->collection(collectionId);
}

#ifndef UNITY_CMAKE_SUPPORT
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#endif

#include "calendarmanager.moc"

#include "moc_calendarmanager.cpp"
