// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "calendareditorbackend.h"
#include "calendarmanager.h"
#include "incidencewrapper.h"

#include <Akonadi/CollectionCreateJob>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KCheckableProxyModel>
#include <KJob>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>
#include <memory>

using namespace Qt::StringLiterals;

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

class ControlledEditorBackend : public CalendarEditorBackend
{
public:
    using CalendarEditorBackend::CalendarEditorBackend;
    int creates = 0;
    int modifies = 0;
    int moves = 0;
    int changeId = 1000;
    bool reject = false;
    bool editing = false;
    Akonadi::Item savedItem;
    KCalendarCore::Incidence::Ptr originalSnapshot;
    Akonadi::Item::List movedItems;
    QPointer<ManualJob> moveJob;

    void finishChange(Akonadi::IncidenceChanger::ResultCode result)
    {
        const auto error = result == Akonadi::IncidenceChanger::ResultCodeSuccess ? QString() : u"Save failed"_s;
        if (editing) {
            Q_EMIT calendarManager()->incidenceChanger()->modifyFinished(changeId, savedItem, result, error);
        } else {
            Q_EMIT calendarManager()->incidenceChanger()->createFinished(changeId, savedItem, result, error);
        }
    }

protected:
    int createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection) override
    {
        ++creates;
        editing = false;
        savedItem = Akonadi::Item(999999);
        savedItem.setMimeType(incidence->mimeType());
        savedItem.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
        savedItem.setParentCollection(collection);
        return reject ? -1 : ++changeId;
    }
    int modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original) override
    {
        ++modifies;
        editing = true;
        savedItem = item;
        originalSnapshot = original;
        return reject ? -1 : ++changeId;
    }
    KJob *moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &) override
    {
        ++moves;
        movedItems = items;
        moveJob = new ManualJob(this);
        return moveJob;
    }
};

class CalendarEditorBackendTest : public QObject
{
    Q_OBJECT

private:
    std::unique_ptr<CalendarManager> m_manager;
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

private Q_SLOTS:
    void initTestCase()
    {
        AkonadiTest::checkTestIsIsolated();
        m_manager = std::make_unique<CalendarManager>();
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
};

QTEST_MAIN(CalendarEditorBackendTest)

#include "calendareditorbackendtest.moc"
