// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "calendareditorbackend.h"
#include "calendarincidencejob.h"
#include "calendarmanager.h"
#include "incidencewrapper.h"

#include <Akonadi/CollectionCreateJob>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemDeleteJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemModifyJob>
#include <KCheckableProxyModel>
#include <KJob>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>
#include <memory>

using namespace Qt::StringLiterals;

class MonitoredWrapper : public IncidenceWrapper
{
public:
    using IncidenceWrapper::IncidenceWrapper;
    using IncidenceWrapper::itemChanged;
    using IncidenceWrapper::itemRemoved;
};

class ManualJob : public KJob
{
public:
    explicit ManualJob(QObject *parent)
        : KJob(parent)
    {
    }
    void start() override
    {
    }
    void finish(bool failed)
    {
        if (failed) {
            setError(UserDefinedError);
            setErrorText(u"Move failed"_s);
        }
        emitResult();
    }
};

struct ControlledChanges {
    CalendarManager *manager = nullptr;
    int creates = 0;
    int modifies = 0;
    int moves = 0;
    int deletes = 0;
    int changeId = 1000;
    bool reject = false;
    bool editing = false;
    Akonadi::Item savedItem;
    KCalendarCore::Incidence::Ptr originalSnapshot;
    Akonadi::Item::List movedItems;
    Akonadi::Item::List deletedItems;
    Akonadi::Item::List modifiedItems;
    QList<int> modificationIds;
    int deletionId = -1;
    QPointer<ManualJob> moveJob;

    void finishChange(Akonadi::IncidenceChanger::ResultCode result)
    {
        const auto error = result == Akonadi::IncidenceChanger::ResultCodeSuccess ? QString() : u"Save failed"_s;
        auto changer = manager->incidenceChanger();
        if (editing) {
            Q_EMIT changer->modifyFinished(changeId, savedItem, result, error);
        } else {
            Q_EMIT changer->createFinished(changeId, savedItem, result, error);
        }
    }
};

class ControlledIncidenceJob : public CalendarIncidenceJob
{
public:
    ControlledIncidenceJob(CalendarManager *manager, ControlledChanges &changes, QObject *parent = nullptr)
        : CalendarIncidenceJob(manager, parent)
        , m_changes(changes)
    {
        m_changes.manager = manager;
    }

protected:
    int createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection) override
    {
        ++m_changes.creates;
        m_changes.editing = false;
        m_changes.savedItem = Akonadi::Item(999999);
        m_changes.savedItem.setMimeType(incidence->mimeType());
        m_changes.savedItem.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
        m_changes.savedItem.setParentCollection(collection);
        return m_changes.reject ? -1 : ++m_changes.changeId;
    }
    int modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original) override
    {
        ++m_changes.modifies;
        m_changes.editing = true;
        m_changes.savedItem = item;
        m_changes.originalSnapshot = original;
        const int id = m_changes.reject ? -1 : ++m_changes.changeId;
        m_changes.modifiedItems.append(item);
        m_changes.modificationIds.append(id);
        return id;
    }
    int deleteIncidences(const Akonadi::Item::List &items) override
    {
        ++m_changes.deletes;
        m_changes.deletedItems = items;
        m_changes.deletionId = m_changes.reject ? -1 : ++m_changes.changeId;
        return m_changes.deletionId;
    }
    KJob *moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &) override
    {
        ++m_changes.moves;
        m_changes.movedItems = items;
        m_changes.moveJob = new ManualJob(this);
        return m_changes.moveJob;
    }

private:
    ControlledChanges &m_changes;
};

class ControlledEditorBackend : public CalendarEditorBackend, public ControlledChanges
{
public:
    using CalendarEditorBackend::CalendarEditorBackend;

    void save(IncidenceWrapper *wrapper, bool editMode)
    {
        CalendarEditorBackend::save(wrapper, editMode);
        // Dispatch job startup; persistence completion is still controlled by the test.
        QCoreApplication::sendPostedEvents(nullptr, QEvent::MetaCall);
    }

protected:
    CalendarIncidenceJob *createJob() override
    {
        return new ControlledIncidenceJob(calendarManager(), *this, this);
    }
};

class ControlledCalendarManager : public CalendarManager
{
public:
    bool controlled = false;
    ControlledChanges changes;

protected:
    CalendarIncidenceJob *createIncidenceJob() override
    {
        return controlled ? new ControlledIncidenceJob(this, changes, this) : CalendarManager::createIncidenceJob();
    }
};

class CalendarEditorBackendTest : public QObject
{
    Q_OBJECT

private:
    std::unique_ptr<ControlledCalendarManager> m_manager;
    Akonadi::Collection m_source;
    Akonadi::Collection m_destination;
    Akonadi::Item m_item;

    void checkCollections(const QModelIndex &parent = {})
    {
        auto model = m_manager->collectionSelectionProxyModel();
        for (int row = 0; row < model->rowCount(parent); ++row) {
            const auto index = model->index(row, 0, parent);
            model->setData(index, Qt::Checked, Qt::CheckStateRole);
            checkCollections(index);
        }
    }

    void createFamily(Akonadi::Item::List &family)
    {
        for (int i = 0; i < 2; ++i) {
            const KCalendarCore::Incidence::Ptr todo(new KCalendarCore::Todo);
            todo->setSummary(i == 0 ? u"Move parent"_s : u"Move child"_s);
            if (i == 1) {
                todo->setRelatedTo(family.first().payload<KCalendarCore::Incidence::Ptr>()->uid());
            }
            Akonadi::Item proposed;
            proposed.setMimeType(todo->mimeType());
            proposed.setPayload<KCalendarCore::Incidence::Ptr>(todo);
            Akonadi::ItemCreateJob create(proposed, m_source);
            create.setAutoDelete(false);
            QVERIFY(create.exec());
            family.append(create.item());
            QTRY_VERIFY(m_manager->incidenceItem(todo).isValid());
        }
    }

private Q_SLOTS:
    void childIncidencesWithoutService()
    {
        IncidenceWrapper wrapper(nullptr);
        QSignalSpy changed(&wrapper, &IncidenceWrapper::childIncidencesChanged);
        wrapper.loadChildIncidences();
        wrapper.setNewTodo();
        QVERIFY(wrapper.childIncidences().isEmpty());
        QCOMPARE(changed.size(), 0);
        IncidenceWrapper draft(m_manager.get());
        draft.loadChildIncidences();
        QVERIFY(draft.childIncidences().isEmpty());
    }

    void childIncidencesLoadOnlyDirectChildren()
    {
        Akonadi::Item::List family;
        createFamily(family);
        for (int i = 0; i < 6; ++i) {
            const KCalendarCore::Incidence::Ptr todo(new KCalendarCore::Todo);
            todo->setRelatedTo(family.last().payload<KCalendarCore::Incidence::Ptr>()->uid());
            Akonadi::Item proposed;
            proposed.setMimeType(todo->mimeType());
            proposed.setPayload<KCalendarCore::Incidence::Ptr>(todo);
            Akonadi::ItemCreateJob create(proposed, m_source);
            create.setAutoDelete(false);
            QVERIFY(create.exec());
            family.append(create.item());
            QTRY_VERIFY(m_manager->incidenceItem(todo).isValid());
        }
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(family.first());
        QVERIFY(wrapper.childIncidences().isEmpty());
        QVERIFY(wrapper.findChildren<IncidenceWrapper *>().isEmpty());
        Q_EMIT m_manager->calendarChanged();
        QVERIFY(wrapper.findChildren<IncidenceWrapper *>().isEmpty());
        wrapper.loadChildIncidences();
        QCOMPARE(wrapper.childIncidences().size(), 1);
        QCOMPARE(wrapper.findChildren<IncidenceWrapper *>().size(), 1);
        auto child = wrapper.childIncidences().first().value<IncidenceWrapper *>();
        QVERIFY(child->childIncidences().isEmpty());
        Q_EMIT m_manager->calendarChanged();
        QCOMPARE(wrapper.findChildren<IncidenceWrapper *>().size(), 1);
        child->loadChildIncidences();
        QCOMPARE(child->childIncidences().size(), 1);
        QCOMPARE(wrapper.findChildren<IncidenceWrapper *>().size(), 2);
    }

    void childIncidenceCache()
    {
        Akonadi::Item::List family;
        createFamily(family);
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(family.first());
        wrapper.loadChildIncidences();
        QCOMPARE(wrapper.childIncidences().size(), 1);
        QPointer<IncidenceWrapper> child = wrapper.childIncidences().first().value<IncidenceWrapper *>();
        QVERIFY(child);
        QSignalSpy changed(&wrapper, &IncidenceWrapper::childIncidencesChanged);
        for (int i = 0; i < 10; ++i) {
            QCOMPARE(wrapper.childIncidences().first().value<IncidenceWrapper *>(), child.data());
        }
        QCOMPARE(changed.count(), 0);
        Q_EMIT m_manager->calendarChanged();
        QCOMPARE(changed.count(), 0);
        QCOMPARE(wrapper.childIncidences().first().value<IncidenceWrapper *>(), child.data());

        auto modified = family.last();
        const KCalendarCore::Incidence::Ptr payload(modified.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setSummary(u"Updated child"_s);
        modified.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        Akonadi::ItemModifyJob update(modified);
        update.setAutoDelete(false);
        QVERIFY(update.exec());
        QTRY_COMPARE(child->summary(), payload->summary());
        QCOMPARE(changed.count(), 0);
        QCOMPARE(wrapper.childIncidences().first().value<IncidenceWrapper *>(), child.data());

        const KCalendarCore::Incidence::Ptr secondChild(new KCalendarCore::Todo);
        secondChild->setRelatedTo(wrapper.uid());
        Akonadi::Item proposed;
        proposed.setMimeType(secondChild->mimeType());
        proposed.setPayload<KCalendarCore::Incidence::Ptr>(secondChild);
        Akonadi::ItemCreateJob create(proposed, m_source);
        create.setAutoDelete(false);
        QVERIFY(create.exec());
        QTRY_COMPARE(wrapper.childIncidences().size(), 2);
        QCOMPARE(changed.count(), 1);
        QVERIFY(wrapper.childIncidences().contains(QVariant::fromValue(child.data())));

        Akonadi::ItemDeleteJob remove(family.last());
        remove.setAutoDelete(false);
        QVERIFY(remove.exec());
        QTRY_COMPARE(wrapper.childIncidences().size(), 1);
        QCOMPARE(changed.count(), 2);
        QTRY_VERIFY(child.isNull());
        QCOMPARE(wrapper.childIncidences().first().value<IncidenceWrapper *>()->uid(), secondChild->uid());

        QPointer<IncidenceWrapper> remaining = wrapper.childIncidences().first().value<IncidenceWrapper *>();
        wrapper.setNewTodo();
        QVERIFY(wrapper.childIncidences().isEmpty());
        QCOMPARE(changed.count(), 3);
        QTRY_VERIFY(remaining.isNull());
        wrapper.setNewEvent();
        QCOMPARE(changed.count(), 3);
    }

    void childIncidenceCacheReparenting()
    {
        Akonadi::Item::List family;
        createFamily(family);
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(family.first());
        wrapper.loadChildIncidences();
        QPointer<IncidenceWrapper> child = wrapper.childIncidences().first().value<IncidenceWrapper *>();
        auto modified = family.last();
        const KCalendarCore::Incidence::Ptr payload(modified.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setRelatedTo({});
        modified.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        Akonadi::ItemModifyJob update(modified);
        update.setAutoDelete(false);
        QVERIFY(update.exec());
        QTRY_VERIFY(wrapper.childIncidences().isEmpty());
        QTRY_VERIFY(child.isNull());
    }

    void childIncidenceCacheForResolvedParent()
    {
        Akonadi::Item::List family;
        createFamily(family);
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(family.last());
        auto parent = wrapper.parentIncidence();
        QVERIFY(parent);
        parent->loadChildIncidences();
        QCOMPARE(parent->childIncidences().size(), 1);
        QCOMPARE(parent->childIncidences().first().value<IncidenceWrapper *>()->uid(), wrapper.uid());
    }

    void childIncidenceCacheCycles()
    {
        Akonadi::Item::List family;
        createFamily(family);
        auto modified = family.first();
        const KCalendarCore::Incidence::Ptr payload(modified.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setRelatedTo(family.last().payload<KCalendarCore::Incidence::Ptr>()->uid());
        modified.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        Akonadi::ItemModifyJob update(modified);
        update.setAutoDelete(false);
        QVERIFY(update.exec());
        QTRY_COMPARE(m_manager->childIncidences(payload->relatedTo()).size(), 1);
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(update.item());
        wrapper.loadChildIncidences();
        QCOMPARE(wrapper.childIncidences().size(), 1);
        auto child = wrapper.childIncidences().first().value<IncidenceWrapper *>();
        child->loadChildIncidences();
        QVERIFY(child->childIncidences().isEmpty());
        Q_EMIT m_manager->calendarChanged();
        QCOMPARE(wrapper.childIncidences().first().value<IncidenceWrapper *>(), child);
        child->loadChildIncidences();
        QVERIFY(child->childIncidences().isEmpty());
    }

    void initTestCase()
    {
        AkonadiTest::checkTestIsIsolated();
        m_manager = std::make_unique<ControlledCalendarManager>();
        m_manager->incidenceChanger()->setShowDialogsOnError(false);

        auto fetch = new Akonadi::CollectionFetchJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive, this);
        QSignalSpy fetched(fetch, &KJob::result);
        QVERIFY(fetched.wait());
        QVERIFY2(!fetch->error(), qPrintable(fetch->errorString()));
        Akonadi::Collection root;
        for (const auto &collection : fetch->collections()) {
            if (collection.resource().startsWith("akonadi_knut_resource"_L1)) {
                root = collection;
                break;
            }
        }
        QVERIFY(root.isValid());
        for (auto collection : {&m_source, &m_destination}) {
            Akonadi::Collection proposed;
            proposed.setParentCollection(root);
            proposed.setName(collection == &m_source ? u"Save source"_s : u"Save destination"_s);
            proposed.setContentMimeTypes({KCalendarCore::Todo::todoMimeType(), KCalendarCore::Event::eventMimeType()});
            proposed.setRights(Akonadi::Collection::AllRights);
            auto create = new Akonadi::CollectionCreateJob(proposed, this);
            QSignalSpy created(create, &KJob::result);
            QVERIFY(created.wait());
            QVERIFY2(!create->error(), qPrintable(create->errorString()));
            *collection = create->collection();
            QTRY_VERIFY(m_manager->getCollection(collection->id()).isValid());
        }
        checkCollections();
        const auto todo = KCalendarCore::Todo::Ptr(new KCalendarCore::Todo);
        todo->setSummary(u"Original title"_s);
        Akonadi::Item proposed;
        proposed.setMimeType(todo->mimeType());
        proposed.setPayload<KCalendarCore::Incidence::Ptr>(todo);
        auto create = new Akonadi::ItemCreateJob(proposed, m_source, this);
        QSignalSpy created(create, &KJob::result);
        QVERIFY(created.wait());
        QVERIFY2(!create->error(), qPrintable(create->errorString()));
        m_item = create->item();
        QTRY_VERIFY(m_manager->incidenceItem(todo).isValid());
    }

    void cleanup()
    {
        m_manager->controlled = false;
        m_manager->changes = {};
    }

    void quickEditWaitsForModificationAndMove()
    {
        m_manager->controlled = true;
        auto &changes = m_manager->changes;
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.setSummary(u"Quick edit"_s);
        wrapper.setCollectionId(m_destination.id());
        auto job = m_manager->editIncidence(&wrapper);
        QSignalSpy result(job, &KJob::result);
        job->start(); // Starting an already started operation must not resubmit it.
        QCOMPARE(changes.modifies, 0);
        QTRY_COMPARE(changes.modifies, 1);
        QCOMPARE(changes.moves, 0);
        QCOMPARE(result.count(), 0);
        changes.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(changes.moves, 1);
        changes.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(changes.moves, 1);
        QCOMPARE(result.count(), 0);
        changes.moveJob->finish(false);
        QCOMPARE(result.count(), 1);
        QCOMPARE(job->error(), 0);
        QCOMPARE(wrapper.collectionId(), m_destination.id());
    }

    void quickEditFailureDoesNotMove()
    {
        m_manager->controlled = true;
        auto &changes = m_manager->changes;
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.setSummary(u"Quick draft"_s);
        wrapper.setCollectionId(m_destination.id());
        const auto cached = m_manager->incidenceItem(wrapper.incidencePtr());
        const auto cachedSummary = cached.payload<KCalendarCore::Incidence::Ptr>()->summary();
        auto job = m_manager->editIncidence(&wrapper);
        QSignalSpy result(job, &KJob::result);
        QSignalSpy errors(m_manager.get(), &CalendarManager::errorOccurred);
        QTRY_COMPARE(changes.modifies, 1);
        // The submitted payload is independent of later edits to the wrapper.
        wrapper.setSummary(u"Later draft"_s);
        QCOMPARE(changes.savedItem.payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Quick draft"_s);
        changes.finishChange(Akonadi::IncidenceChanger::ResultCodeJobError);
        QCOMPARE(changes.moves, 0);
        QCOMPARE(result.count(), 1);
        QCOMPARE(errors.count(), 1);
        QCOMPARE(job->errorText(), u"Save failed"_s);
        QCOMPARE(wrapper.summary(), u"Later draft"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), m_item.revision());
        QCOMPARE(cached.payload<KCalendarCore::Incidence::Ptr>()->summary(), cachedSummary);
    }

    void dateChangeFinishesAfterPersistence_data()
    {
        QTest::addColumn<bool>("failed");
        QTest::newRow("success") << false;
        QTest::newRow("failure") << true;
    }

    void dateChangeFinishesAfterPersistence()
    {
        QFETCH(bool, failed);
        m_manager->controlled = true;
        auto &changes = m_manager->changes;
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        const QDateTime due(QDate(2026, 7, 15), QTime(10, 0), QTimeZone::UTC);
        wrapper.incidencePtr().staticCast<KCalendarCore::Todo>()->setDtDue(due);
        const auto cachedDue =
            m_manager->incidenceItem(wrapper.incidencePtr()).payload<KCalendarCore::Incidence::Ptr>().staticCast<KCalendarCore::Todo>()->dtDue();
        QSignalSpy terminal(m_manager.get(), &CalendarManager::updateIncidenceDatesFinished);
        auto job = m_manager->updateIncidenceDates(&wrapper, 3600000, 3600000);
        QSignalSpy result(job, &KJob::result);
        QCOMPARE(terminal.count(), 0);
        QTRY_COMPARE(changes.modifies, 1);
        QCOMPARE(terminal.count(), 0);
        QCOMPARE(wrapper.incidencePtr().staticCast<KCalendarCore::Todo>()->dtDue(), due);
        QCOMPARE(changes.savedItem.payload<KCalendarCore::Incidence::Ptr>().staticCast<KCalendarCore::Todo>()->dtDue(), due.addSecs(3600));
        QCOMPARE(m_manager->incidenceItem(wrapper.incidencePtr()).payload<KCalendarCore::Incidence::Ptr>().staticCast<KCalendarCore::Todo>()->dtDue(),
                 cachedDue);
        changes.finishChange(failed ? Akonadi::IncidenceChanger::ResultCodeJobError : Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(result.count(), 1);
        QCOMPARE(terminal.count(), 1);
        QCOMPARE(bool(job->error()), failed);
        QCOMPARE(wrapper.incidencePtr().staticCast<KCalendarCore::Todo>()->dtDue(), failed ? due : due.addSecs(3600));
    }

    void recurrenceDateChangeCreatesException_data()
    {
        QTest::addColumn<int>("scope");
        QTest::newRow("selected") << int(IncidenceWrapper::SelectedOccurrence);
        QTest::newRow("future") << int(IncidenceWrapper::FutureOccurrences);
    }

    void recurrenceDateChangeCreatesException()
    {
        QFETCH(int, scope);
        m_manager->controlled = true;
        auto &changes = m_manager->changes;
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        const QDateTime start(QDate(2026, 7, 15), QTime(9, 0), QTimeZone::UTC);
        const auto todo = wrapper.incidencePtr().staticCast<KCalendarCore::Todo>();
        todo->setDtStart(start);
        todo->setDtDue(start.addSecs(3600));
        todo->recurrence()->setDaily(1);
        const auto occurrence = start.addDays(2);
        auto job = m_manager->updateIncidenceDates(&wrapper, 3600000, 3600000, scope, occurrence);
        QSignalSpy result(job, &KJob::result);
        QTRY_COMPARE(changes.creates, 1);
        QCOMPARE(changes.modifies, 0);
        const auto exception = changes.savedItem.payload<KCalendarCore::Incidence::Ptr>();
        QCOMPARE(exception->recurrenceId(), occurrence);
        QCOMPARE(exception->thisAndFuture(), scope == IncidenceWrapper::FutureOccurrences);
        QVERIFY(!exception->recurs());
        QCOMPARE(exception.staticCast<KCalendarCore::Todo>()->dtDue(), occurrence.addSecs(7200));
        QCOMPARE(result.count(), 0);
        changes.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(result.count(), 1);
        QCOMPARE(wrapper.incidenceItem().id(), m_item.id());
        QVERIFY(wrapper.incidencePtr()->recurs());
        QCOMPARE(wrapper.incidencePtr()->dtStart(), start);
    }

    void rejectedDateChangeStillReleasesInteraction()
    {
        m_manager->controlled = true;
        QSignalSpy terminal(m_manager.get(), &CalendarManager::updateIncidenceDatesFinished);
        QSignalSpy errors(m_manager.get(), &CalendarManager::errorOccurred);
        auto job = m_manager->updateIncidenceDates(nullptr, 0, 0);
        job->setAutoDelete(false);
        QSignalSpy result(job, &KJob::result);
        QCOMPARE(terminal.count(), 0);
        QTRY_COMPARE(terminal.count(), 1);
        QCOMPARE(result.count(), 1);
        QCOMPARE(errors.count(), 1);
        QVERIFY(job->error());
    }

    void deletingParentDoesNotMutateCachedChildren()
    {
        const KCalendarCore::Incidence::Ptr child(new KCalendarCore::Todo);
        child->setSummary(u"Child task"_s);
        child->setRelatedTo(m_item.payload<KCalendarCore::Incidence::Ptr>()->uid());
        Akonadi::Item proposed;
        proposed.setMimeType(child->mimeType());
        proposed.setPayload<KCalendarCore::Incidence::Ptr>(child);
        Akonadi::ItemCreateJob create(proposed, m_source);
        create.setAutoDelete(false);
        QVERIFY(create.exec());
        QTRY_VERIFY(m_manager->incidenceItem(child).isValid());
        QTRY_COMPARE(m_manager->childIncidences(child->relatedTo()).size(), 1);
        m_manager->controlled = true;
        auto &changes = m_manager->changes;
        auto job = m_manager->deleteIncidence(m_item.payload<KCalendarCore::Incidence::Ptr>());
        QSignalSpy result(job, &KJob::result);
        QTRY_COMPARE(changes.deletes, 1);
        QCOMPARE(changes.modifies, 1);
        QCOMPARE(changes.modifiedItems.first().payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        const auto cached = m_manager->incidenceItem(child).payload<KCalendarCore::Incidence::Ptr>();
        QCOMPARE(cached->relatedTo(), child->relatedTo());
        auto changer = m_manager->incidenceChanger();
        Q_EMIT changer->modifyFinished(changes.modificationIds.first(), {}, Akonadi::IncidenceChanger::ResultCodeJobError, u"Child update failed"_s);
        QCOMPARE(result.count(), 0);
        Q_EMIT changer->deleteFinished(changes.deletionId, {}, Akonadi::IncidenceChanger::ResultCodeRolledback, u"Rolled back"_s);
        QCOMPARE(result.count(), 1);
        QCOMPARE(job->errorText(), u"Child update failed"_s);
        QCOMPARE(cached->relatedTo(), child->relatedTo());
        Akonadi::ItemDeleteJob remove(create.item());
        remove.setAutoDelete(false);
        QVERIFY(remove.exec());
        QTRY_VERIFY(!m_manager->incidenceItem(child).isValid());
    }

    void jobDestructionDisconnectsPendingChanges()
    {
        ControlledChanges changes;
        auto owner = std::make_unique<QObject>();
        auto job = new ControlledIncidenceJob(m_manager.get(), changes, owner.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        QVERIFY(job->prepareSave(&wrapper, true));
        job->start();
        QTRY_COMPARE(changes.modifies, 1);
        QPointer<CalendarIncidenceJob> guarded(job);
        owner.reset();
        QVERIFY(!guarded);
        changes.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(wrapper.incidenceItem().revision(), m_item.revision());
    }

    void movesFamilyAndDeletesParentUsingRealJobs()
    {
        Akonadi::Item::List family;
        createFamily(family);
        QCOMPARE(family.size(), 2);
        const auto parent = family.first().payload<KCalendarCore::Incidence::Ptr>();
        const auto child = family.last().payload<KCalendarCore::Incidence::Ptr>();
        QTRY_COMPARE(m_manager->childIncidences(parent->uid()).size(), 1);
        std::unique_ptr<CalendarIncidenceJob> move(m_manager->changeIncidenceCollection(child, m_destination.id()));
        move->setAutoDelete(false);
        QSignalSpy moved(move.get(), &KJob::result);
        QTRY_COMPARE(moved.count(), 1);
        QVERIFY2(!move->error(), qPrintable(move->errorText()));
        QTRY_COMPARE(m_manager->incidenceItem(parent).parentCollection().id(), m_destination.id());
        QTRY_COMPARE(m_manager->incidenceItem(child).parentCollection().id(), m_destination.id());
        // Older Akonadi Calendar drops the child index when reinserting the parent.
        // Keep this combined regression test without requiring that dependency fix.
        const bool lostChildLinks = m_manager->childIncidences(parent->uid()).isEmpty();
        std::unique_ptr<CalendarIncidenceJob> remove(m_manager->deleteIncidence(parent));
        remove->setAutoDelete(false);
        QSignalSpy removed(remove.get(), &KJob::result);
        QTRY_COMPARE(removed.count(), 1);
        QVERIFY2(!remove->error(), qPrintable(remove->errorText()));
        QTRY_VERIFY(!m_manager->incidenceItem(parent).isValid());
        if (lostChildLinks) {
            QEXPECT_FAIL("", "Akonadi Calendar loses child links when reinserting their parent", Continue);
            QCOMPARE(m_manager->incidenceItem(child).payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        } else {
            QTRY_COMPARE(m_manager->incidenceItem(child).payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        }
        Akonadi::ItemFetchJob fetch(family.last());
        fetch.setAutoDelete(false);
        fetch.fetchScope().fetchFullPayload();
        fetch.fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
        QVERIFY(fetch.exec());
        QCOMPARE(fetch.items().size(), 1);
        QCOMPARE(fetch.items().first().parentCollection().id(), m_destination.id());
        if (lostChildLinks) {
            QEXPECT_FAIL("", "Akonadi Calendar loses child links when reinserting their parent", Continue);
        }
        QCOMPARE(fetch.items().first().payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        Akonadi::ItemDeleteJob cleanup(family.last());
        cleanup.setAutoDelete(false);
        QVERIFY(cleanup.exec());
        QTRY_VERIFY(!m_manager->incidenceItem(child).isValid());
    }

    void deletesParentAndKeepsChildrenUsingRealJobs()
    {
        Akonadi::Item::List family;
        createFamily(family);
        QCOMPARE(family.size(), 2);
        const auto parent = family.first().payload<KCalendarCore::Incidence::Ptr>();
        const auto child = family.last().payload<KCalendarCore::Incidence::Ptr>();
        QTRY_COMPARE(m_manager->childIncidences(parent->uid()).size(), 1);
        std::unique_ptr<CalendarIncidenceJob> job(m_manager->deleteIncidence(parent));
        job->setAutoDelete(false);
        QSignalSpy result(job.get(), &KJob::result);
        QTRY_COMPARE(result.count(), 1);
        QVERIFY2(!job->error(), qPrintable(job->errorText()));
        QTRY_VERIFY(!m_manager->incidenceItem(parent).isValid());
        QTRY_COMPARE(m_manager->incidenceItem(child).payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        Akonadi::ItemFetchJob fetch(family.last());
        fetch.setAutoDelete(false);
        fetch.fetchScope().fetchFullPayload();
        fetch.fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
        QVERIFY(fetch.exec());
        QCOMPARE(fetch.items().size(), 1);
        QCOMPARE(fetch.items().first().payload<KCalendarCore::Incidence::Ptr>()->relatedTo(), QString());
        Akonadi::ItemDeleteJob cleanup(family.last());
        cleanup.setAutoDelete(false);
        QVERIFY(cleanup.exec());
        QTRY_VERIFY(!m_manager->incidenceItem(child).isValid());
    }

    void wrapperStoresEditorSnapshotIndependently()
    {
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        auto updated = m_item;
        updated.setRevision(m_item.revision() + 1);
        updated.setParentCollection(m_destination);
        const KCalendarCore::Incidence::Ptr saved(updated.payload<KCalendarCore::Incidence::Ptr>()->clone());
        saved->setSummary(u"Persisted snapshot"_s);
        updated.setPayload<KCalendarCore::Incidence::Ptr>(saved);
        wrapper.setIncidenceItem(updated);
        QCOMPARE(wrapper.incidenceItem().revision(), updated.revision());
        QCOMPARE(wrapper.collectionId(), m_destination.id());
        wrapper.triggerEditMode();
        QCOMPARE(wrapper.incidenceItem().revision(), updated.revision());
        QCOMPARE(wrapper.incidenceItem().parentCollection().id(), m_destination.id());
        wrapper.setSummary(u"Draft title"_s);
        QCOMPARE(wrapper.originalIncidencePtr()->summary(), u"Persisted snapshot"_s);
        QCOMPARE(saved->summary(), u"Persisted snapshot"_s);
    }

    void externalUpdatesPreserveDraftAndOriginalRevision()
    {
        MonitoredWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Unsaved draft"_s);
        QSignalSpy changed(&wrapper, &IncidenceWrapper::externalChangeChanged);
        wrapper.itemChanged(m_item); // Initial fetch of the unchanged revision.
        QVERIFY(!wrapper.hasExternalChanges());
        auto external = m_item;
        external.setRevision(m_item.revision() + 1);
        const KCalendarCore::Incidence::Ptr payload(m_item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setSummary(u"External title"_s);
        external.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        wrapper.itemChanged(external);
        QCOMPARE(changed.count(), 1);
        QVERIFY(wrapper.hasExternalChanges());
        QVERIFY(!wrapper.incidenceDeleted());
        QCOMPARE(wrapper.summary(), u"Unsaved draft"_s);
        QCOMPARE(wrapper.originalIncidencePtr()->summary(), u"Original title"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), m_item.revision());
        QCOMPARE(wrapper.incidenceItem().payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Original title"_s);
        // A caller/cache mutation must not change the pending reload snapshot.
        payload->setSummary(u"Later mutation"_s);
        wrapper.itemChanged(m_item);
        QVERIFY(wrapper.reloadLatest());
        QCOMPARE(wrapper.summary(), u"External title"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), external.revision());
        QVERIFY(!wrapper.hasExternalChanges());
        wrapper.setSummary(u"New draft"_s);
        QCOMPARE(wrapper.originalIncidencePtr()->summary(), u"External title"_s);
        QCOMPARE(wrapper.incidenceItem().payload<KCalendarCore::Incidence::Ptr>()->summary(), u"External title"_s);
    }

    void deletionPreservesDraftAndDisablesReload()
    {
        MonitoredWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Deleted incidence draft"_s);
        wrapper.itemRemoved();
        QVERIFY(wrapper.hasExternalChanges());
        QVERIFY(wrapper.incidenceDeleted());
        QVERIFY(!wrapper.reloadLatest());
        QCOMPARE(wrapper.summary(), u"Deleted incidence draft"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), m_item.revision());
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        backend.save(&wrapper, true);
        QCOMPARE(backend.modifies, 0);
        QVERIFY(!backend.errorMessage().isEmpty());
        QVERIFY(!backend.saving());
    }

    void conflictingSaveKeepsDraftUntilReload()
    {
        MonitoredWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Unsaved conflict draft"_s);
        auto external = m_item;
        external.setRevision(m_item.revision() + 1);
        const KCalendarCore::Incidence::Ptr payload(m_item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setSummary(u"Changed outside editor"_s);
        external.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        wrapper.itemChanged(external);
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        backend.save(&wrapper, true);
        QCOMPARE(backend.modifies, 0);
        QVERIFY(!backend.errorMessage().isEmpty());
        QCOMPARE(wrapper.summary(), u"Unsaved conflict draft"_s);
        backend.reload(&wrapper);
        QCOMPARE(wrapper.summary(), u"Changed outside editor"_s);
        QVERIFY(backend.errorMessage().isEmpty());
        backend.save(&wrapper, true);
        QCOMPARE(backend.modifies, 1);
        QCOMPARE(backend.savedItem.revision(), external.revision());
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeJobError);
        QVERIFY(!backend.saving());
        QCOMPARE(wrapper.summary(), u"Changed outside editor"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), external.revision());
    }

    void liveWrappersStillFollowUpdates()
    {
        MonitoredWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        auto external = m_item;
        external.setRevision(m_item.revision() + 1);
        const KCalendarCore::Incidence::Ptr payload(m_item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setSummary(u"Live updated title"_s);
        external.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        wrapper.itemChanged(external);
        QCOMPARE(wrapper.summary(), u"Live updated title"_s);
        QVERIFY(!wrapper.hasExternalChanges());
    }

    void rejectsMissingCalendarAndOriginal()
    {
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setSummary(u"Unsaved draft"_s);
        wrapper.setCollectionId(-1);
        backend.save(&wrapper, false);
        QVERIFY(!backend.errorMessage().isEmpty());
        QVERIFY(!backend.saving());
        QCOMPARE(backend.creates, 0);
        wrapper.setCollectionId(m_source.id());
        backend.save(&wrapper, true);
        QVERIFY(!backend.errorMessage().isEmpty());
        QCOMPARE(backend.modifies, 0);
    }

    void retainsDraftOnFailureAndAllowsRetry()
    {
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setSummary(u"Draft title"_s);
        wrapper.setCollectionId(m_source.id());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        QSignalSpy saving(&backend, &CalendarEditorBackend::savingChanged);
        backend.save(&wrapper, false);
        QVERIFY(backend.saving());
        backend.save(&wrapper, false);
        QCOMPARE(backend.creates, 1);
        // Completion of another operation must not finish this editor's save.
        Q_EMIT m_manager->incidenceChanger()->createFinished(backend.changeId + 1, {}, Akonadi::IncidenceChanger::ResultCodeSuccess, {});
        QVERIFY(backend.saving());
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeJobError);
        QCOMPARE(saving.count(), 2);
        QCOMPARE(finished.count(), 0);
        QCOMPARE(wrapper.summary(), u"Draft title"_s);
        QVERIFY(!wrapper.incidenceItem().isValid());
        backend.save(&wrapper, false);
        QVERIFY(backend.errorMessage().isEmpty());
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(finished.count(), 1);
        QVERIFY(!backend.saving());
        QVERIFY(wrapper.incidenceItem().isValid());
    }

    void handlesImmediateRejection()
    {
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        backend.reject = true;
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setSummary(u"Draft title"_s);
        wrapper.setCollectionId(m_source.id());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        backend.save(&wrapper, false);
        QVERIFY(!backend.saving());
        QVERIFY(!backend.errorMessage().isEmpty());
        QCOMPARE(finished.count(), 0);
    }

    void movesOnlyAfterSuccessfulModification()
    {
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Updated title"_s);
        wrapper.setCollectionId(m_destination.id());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        backend.save(&wrapper, true);
        QVERIFY(backend.saving());
        QCOMPARE(backend.moves, 0);
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeJobError);
        QCOMPARE(backend.moves, 0);
        QCOMPARE(finished.count(), 0);
        backend.save(&wrapper, true);
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QCOMPARE(backend.moves, 1);
        QVERIFY(backend.saving());
        QCOMPARE(finished.count(), 0);
        QCOMPARE(backend.movedItems.first().id(), m_item.id());
        backend.moveJob->finish(false);
        QVERIFY(!backend.saving());
        QCOMPARE(finished.count(), 1);
        QCOMPARE(wrapper.incidenceItem().parentCollection().id(), m_destination.id());
    }

    void reportsPartialSuccessWhenMovingFails()
    {
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Saved title"_s);
        wrapper.setCollectionId(m_destination.id());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        backend.save(&wrapper, true);
        const auto persistedRevision = m_item.revision() + 1;
        backend.savedItem.setRevision(persistedRevision);
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        QVERIFY(backend.moveJob);
        backend.moveJob->finish(true);
        QVERIFY(!backend.saving());
        QVERIFY(backend.errorMessage().contains(u"saved"_s));
        QCOMPARE(finished.count(), 0);
        QCOMPARE(wrapper.summary(), u"Saved title"_s);
        QCOMPARE(wrapper.originalIncidencePtr()->summary(), u"Saved title"_s);
        QCOMPARE(wrapper.incidenceItem().parentCollection().id(), m_source.id());
        QCOMPARE(wrapper.collectionId(), m_destination.id());
        wrapper.setSummary(u"Retry title"_s);
        QCOMPARE(backend.savedItem.payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Saved title"_s);
        backend.save(&wrapper, true);
        QCOMPARE(backend.savedItem.revision(), persistedRevision);
        QCOMPARE(backend.savedItem.payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Retry title"_s);
        QCOMPARE(backend.originalSnapshot->summary(), u"Saved title"_s);
        backend.finishChange(Akonadi::IncidenceChanger::ResultCodeSuccess);
        backend.moveJob->finish(false);
        QCOMPARE(finished.count(), 1);
        QCOMPARE(wrapper.incidenceItem().parentCollection().id(), m_destination.id());
    }

    void savesUsingRealChanger()
    {
        CalendarEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setSummary(u"Persisted title"_s);
        wrapper.setCollectionId(m_source.id());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        backend.save(&wrapper, false);
        QTRY_COMPARE(finished.count(), 1);
        QVERIFY(backend.errorMessage().isEmpty());
        QVERIFY(wrapper.incidenceItem().isValid());
        const auto uid = wrapper.uid();
        QTRY_VERIFY(m_manager->incidenceItem(uid).isValid());
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Persisted edit"_s);
        backend.save(&wrapper, true);
        QTRY_COMPARE(finished.count(), 2);
        QVERIFY(backend.errorMessage().isEmpty());
        auto fetch = new Akonadi::ItemFetchJob(wrapper.incidenceItem(), this);
        fetch->fetchScope().fetchFullPayload();
        QSignalSpy fetched(fetch, &KJob::result);
        QVERIFY(fetched.wait());
        QVERIFY2(!fetch->error(), qPrintable(fetch->errorString()));
        QCOMPARE(fetch->items().size(), 1);
        QCOMPARE(fetch->items().first().payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Persisted edit"_s);
    }
    void realNotificationsPreserveDraft()
    {
        const KCalendarCore::Incidence::Ptr todo(new KCalendarCore::Todo);
        todo->setSummary(u"Original external test"_s);
        Akonadi::Item proposed;
        proposed.setMimeType(todo->mimeType());
        proposed.setPayload<KCalendarCore::Incidence::Ptr>(todo);
        Akonadi::ItemCreateJob create(proposed, m_source);
        create.setAutoDelete(false);
        QVERIFY(create.exec());
        const auto original = create.item();
        QTRY_VERIFY(m_manager->incidenceItem(todo).isValid());
        MonitoredWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(original);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Unsaved real draft"_s);
        auto external = original;
        const KCalendarCore::Incidence::Ptr payload(todo->clone());
        payload->setSummary(u"External persisted title"_s);
        external.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        Akonadi::ItemModifyJob modify(external);
        modify.setAutoDelete(false);
        modify.disableAutomaticConflictHandling();
        QVERIFY(modify.exec());
        QTRY_VERIFY(wrapper.hasExternalChanges());
        QCOMPARE(wrapper.summary(), u"Unsaved real draft"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), original.revision());
        ControlledEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        backend.save(&wrapper, true);
        QCOMPARE(backend.modifies, 0);
        backend.reload(&wrapper);
        QCOMPARE(wrapper.summary(), u"External persisted title"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), modify.item().revision());
        wrapper.setSummary(u"Draft before deletion"_s);
        Akonadi::ItemDeleteJob remove(wrapper.incidenceItem());
        remove.setAutoDelete(false);
        QVERIFY(remove.exec());
        QTRY_VERIFY(wrapper.incidenceDeleted());
        QCOMPARE(wrapper.summary(), u"Draft before deletion"_s);
        backend.save(&wrapper, true);
        QCOMPARE(backend.modifies, 0);
        QCOMPARE(wrapper.summary(), u"Draft before deletion"_s);
    }

    void saveRejectsStaleRevisionFromCalendarCache()
    {
        auto changer = m_manager->incidenceChanger();
        QSignalSpy modified(changer, &Akonadi::IncidenceChanger::modifyFinished);
        auto updated = m_item;
        const KCalendarCore::Incidence::Ptr payload(m_item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        payload->setSummary(u"Newer persisted revision"_s);
        updated.setPayload<KCalendarCore::Incidence::Ptr>(payload);
        QVERIFY(changer->modifyIncidence(updated, m_item.payload<KCalendarCore::Incidence::Ptr>()) >= 0);
        QTRY_COMPARE(modified.count(), 1);
        QCOMPARE(modified.at(0).at(2).value<Akonadi::IncidenceChanger::ResultCode>(), Akonadi::IncidenceChanger::ResultCodeSuccess);
        const auto latest = modified.at(0).at(1).value<Akonadi::Item>();
        QVERIFY(latest.revision() > m_item.revision());
        QTRY_COMPARE(m_manager->incidenceItem(payload).revision(), latest.revision());
        IncidenceWrapper wrapper(m_manager.get());
        wrapper.setIncidenceItem(m_item);
        wrapper.triggerEditMode();
        wrapper.setSummary(u"Stale draft"_s);
        CalendarEditorBackend backend;
        backend.setCalendarManager(m_manager.get());
        QSignalSpy finished(&backend, &CalendarEditorBackend::finished);
        backend.save(&wrapper, true);
        QVERIFY(!backend.saving());
        QVERIFY(!backend.errorMessage().isEmpty());
        QVERIFY(wrapper.hasExternalChanges());
        QCOMPARE(wrapper.summary(), u"Stale draft"_s);
        QCOMPARE(wrapper.incidenceItem().revision(), m_item.revision());
        QCOMPARE(finished.count(), 0);
        QCOMPARE(modified.count(), 1);
        auto fetch = new Akonadi::ItemFetchJob(latest, this);
        fetch->fetchScope().fetchFullPayload();
        QSignalSpy fetched(fetch, &KJob::result);
        QVERIFY(fetched.wait());
        QVERIFY2(!fetch->error(), qPrintable(fetch->errorString()));
        QCOMPARE(fetch->items().first().payload<KCalendarCore::Incidence::Ptr>()->summary(), u"Newer persisted revision"_s);
        backend.reload(&wrapper);
        QCOMPARE(wrapper.summary(), u"Newer persisted revision"_s);
        QVERIFY(!wrapper.hasExternalChanges());
        QVERIFY(backend.errorMessage().isEmpty());
        wrapper.setSummary(u"Rebased draft"_s);
        backend.save(&wrapper, true);
        QTRY_COMPARE(finished.count(), 1);
        QVERIFY(backend.errorMessage().isEmpty());
        QCOMPARE(wrapper.summary(), u"Rebased draft"_s);
    }
};

QTEST_MAIN(CalendarEditorBackendTest)

#include "calendareditorbackendtest.moc"
