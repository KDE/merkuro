// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "models/attachmentsmodel.h"
#include "models/attendeesmodel.h"
#include "models/hourlyincidencemodel.h"
#include "models/itemtagsmodel.h"
#include "models/multidayincidencemodel.h"
#include "models/recurrenceexceptionsmodel.h"
#include "models/todosortfilterproxymodel.h"
#include "remindersmodel.h"

#include <Akonadi/Tag>
#include <QAbstractItemModelTester>
#include <QPersistentModelIndex>
#include <QSignalSpy>
#include <QStandardItemModel>
#include <QTest>

using namespace Qt::Literals::StringLiterals;

class TestTodoProxy : public TodoSortFilterProxyModel
{
public:
    using TodoSortFilterProxyModel::lessThan;
};

// Supply occurrences directly so layout tests need neither Akonadi nor a resource.
class TestOccurrenceModel : public IncidenceOccurrenceModel
{
public:
    QList<KCalendarCore::Event::Ptr> events;

    int rowCount(const QModelIndex &parent = {}) const override
    {
        return parent.isValid() ? 0 : events.size();
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        const auto event = events.at(index.row());
        switch (role) {
        case StartTime:
            return QVariant::fromValue(Merkuro::KDateTime(event->dtStart()));
        case EndTime:
            return QVariant::fromValue(Merkuro::KDateTime(event->dtEnd()));
        case Summary:
            return event->summary();
        case AllDay:
            return event->allDay();
        default:
            return {};
        }
    }
};

class EditorModelsTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void reminders()
    {
        RemindersModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QSignalSpy inserted(&model, &QAbstractItemModel::rowsInserted);
        QSignalSpy removed(&model, &QAbstractItemModel::rowsRemoved);
        QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
        QSignalSpy changed(&model, &RemindersModel::alarmsChanged);
        model.addAlarm();
        QVERIFY(!model.data({}, Qt::DisplayRole).isValid());
        QVERIFY(!model.setData({}, 0, RemindersModel::StartOffsetRole));
        auto event = KCalendarCore::Event::Ptr::create();
        model.setIncidence(event);
        QCOMPARE(reset.count(), 1);
        model.addAlarm();
        model.addAlarm();
        QCOMPARE(inserted.count(), 2);
        QPersistentModelIndex survivor(model.index(1));
        model.deleteAlarm(0);
        QCOMPARE(removed.count(), 1);
        QVERIFY(survivor.isValid());
        QCOMPARE(survivor.row(), 0);
        QCOMPARE(model.rowCount(survivor), 0);
        QVERIFY(model.setData(survivor, -60, RemindersModel::StartOffsetRole));
        QCOMPARE(changed.count(), 5);
        model.deleteAlarm(42);
        QCOMPARE(removed.count(), 1);
        model.setIncidence({});
        QVERIFY(!survivor.isValid());
        QCOMPARE(model.rowCount(), 0);
    }

    void attachments()
    {
        AttachmentsModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QSignalSpy inserted(&model, &QAbstractItemModel::rowsInserted);
        QSignalSpy removed(&model, &QAbstractItemModel::rowsRemoved);
        model.addAttachment(u"file:///tmp/a.txt"_s);
        QCOMPARE(model.rowCount(), 0);
        model.setIncidencePtr(KCalendarCore::Event::Ptr::create());
        model.addAttachment({});
        QCOMPARE(inserted.count(), 0);
        model.addAttachment(u"file:///tmp/a.txt"_s);
        model.addAttachment(u"file:///tmp/b.txt"_s);
        model.addAttachment(u"file:///tmp/a.txt"_s);
        QCOMPARE(inserted.count(), 3);
        QPersistentModelIndex survivor(model.index(1));
        model.deleteAttachment(u"file:///tmp/a.txt"_s);
        QCOMPARE(removed.count(), 2);
        QCOMPARE(model.rowCount(), 1);
        QVERIFY(survivor.isValid());
        QCOMPARE(survivor.row(), 0);
        QCOMPARE(survivor.data(AttachmentsModel::URIRole).toString(), u"file:///tmp/b.txt"_s);
        model.deleteAttachment(u"file:///tmp/missing.txt"_s);
        QCOMPARE(removed.count(), 2);
        model.setIncidencePtr({});
        QVERIFY(!survivor.isValid());
        QCOMPARE(model.attachments().size(), 0);
    }

    void attendees()
    {
        AttendeesModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QAbstractItemModelTester statusTester(model.attendeeStatusModel(), QAbstractItemModelTester::FailureReportingMode::QtTest);
        QSignalSpy inserted(&model, &QAbstractItemModel::rowsInserted);
        QSignalSpy removed(&model, &QAbstractItemModel::rowsRemoved);
        QSignalSpy changed(&model, &AttendeesModel::attendeesChanged);
        model.addAttendee();
        QCOMPARE(model.rowCount(), 0);
        model.setIncidencePtr(KCalendarCore::Event::Ptr::create());
        model.addAttendee();
        model.addAttendee();
        QCOMPARE(inserted.count(), 2);
        QPersistentModelIndex survivor(model.index(1));
        QVERIFY(model.setData(survivor, u"Alice"_s, AttendeesModel::NameRole));
        QCOMPARE(changed.count(), 4);
        model.deleteAttendee(0);
        QCOMPARE(removed.count(), 1);
        QVERIFY(survivor.isValid());
        QCOMPARE(survivor.row(), 0);
        QCOMPARE(survivor.data(AttendeesModel::NameRole).toString(), u"Alice"_s);
        model.setIncidencePtr({});
        QVERIFY(!survivor.isValid());
        QCOMPARE(model.attendees().size(), 0);
    }

    void exceptions()
    {
        auto event = KCalendarCore::Event::Ptr::create();
        event->setDtStart(QDate(2026, 10, 2).startOfDay());
        event->recurrence()->setDaily(1);
        event->recurrence()->addExDate(QDate(2026, 10, 3));
        RecurrenceExceptionsModel model(nullptr, event);
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QCOMPARE(model.rowCount(), 1); // Constructor must load existing exceptions.
        QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
        const Merkuro::KDateTime date(QDate(2026, 10, 4).startOfDay());
        model.addExceptionDateTime(date);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(reset.count(), 1);
        model.deleteExceptionDateTime(date);
        QCOMPARE(model.rowCount(), 1);
        // Imported timed exceptions on the same date must all be removed.
        event->recurrence()->addExDateTime(date.dateTime().addSecs(3600));
        event->recurrence()->addExDateTime(date.dateTime().addSecs(7200));
        model.updateExceptions();
        QCOMPARE(model.rowCount(), 3);
        model.deleteExceptionDateTime(date);
        QCOMPARE(model.rowCount(), 1);
        event->setAllDay(true);
        model.deleteExceptionDateTime(date); // Missing timestamp must not remove row -1.
        QCOMPARE(model.rowCount(), 1);
        model.setIncidencePtr({});
        QCOMPARE(model.rowCount(), 0);
        model.addExceptionDateTime(date);
        model.deleteExceptionDateTime(date);
    }

    void tags()
    {
        ItemTagsModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
        Akonadi::Item item(1);
        Akonadi::Tag tag(1);
        tag.setName(u"Work"_s);
        item.setTags({tag});
        model.setItem(item);
        QCOMPARE(reset.count(), 1);
        QCOMPARE(model.rowCount(), 1);
        QPersistentModelIndex oldIndex(model.index(0));
        QCOMPARE(oldIndex.data(ItemTagsModel::NameRole).toString(), u"Work"_s);
        item.setTags({}); // Same item ID, different tag list.
        model.setItem(item);
        QCOMPARE(reset.count(), 2);
        QCOMPARE(model.rowCount(), 0);
        QVERIFY(!oldIndex.isValid());
    }

    void multiDaySorting()
    {
        TestOccurrenceModel source;
        const auto start = QDate(2026, 10, 2).startOfDay();
        source.setStart(Merkuro::KDateTime(start));
        source.setLength(7);
        auto earlier = KCalendarCore::Event::Ptr::create();
        earlier->setSummary(u"Earlier long event"_s);
        earlier->setDtStart(start.addSecs(3600));
        earlier->setDtEnd(start.addDays(2));
        auto later = KCalendarCore::Event::Ptr::create();
        later->setSummary(u"Later short event"_s);
        later->setDtStart(start.addSecs(7200));
        later->setDtEnd(start.addSecs(10800));
        // The longer event starts first, regardless of the source order.
        source.events = {later, earlier};
        MultiDayIncidenceModel model;
        model.componentComplete();
        model.setModel(&source);
        const auto lines = model.index(0, 0).data(MultiDayIncidenceModel::IncidencesRole).toList();
        QCOMPARE(lines.size(), 2);
        const auto firstLine = lines.first().value<QList<IncidenceData>>();
        QCOMPARE(firstLine.size(), 1);
        QCOMPARE(firstLine.first().text, earlier->summary());
    }

    void readOnlyIncidence()
    {
        auto event = KCalendarCore::Event::Ptr::create();
        event->setReadOnly(true);
        AttendeesModel attendees(nullptr, event);
        AttachmentsModel attachments(nullptr, event);
        RecurrenceExceptionsModel exceptions(nullptr, event);
        RemindersModel reminders;
        reminders.setIncidence(event);
        QAbstractItemModelTester attendeeTester(&attendees, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QAbstractItemModelTester attachmentTester(&attachments, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QAbstractItemModelTester exceptionTester(&exceptions, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QAbstractItemModelTester reminderTester(&reminders, QAbstractItemModelTester::FailureReportingMode::QtTest);
        attendees.addAttendee();
        attachments.addAttachment(u"file:///tmp/a.txt"_s);
        reminders.addAlarm();
        exceptions.addExceptionDateTime(Merkuro::KDateTime(QDate(2026, 10, 2).startOfDay()));
        QCOMPARE(attendees.rowCount(), 0);
        QCOMPARE(attachments.rowCount(), 0);
        QCOMPARE(reminders.rowCount(), 0);
        QCOMPARE(exceptions.rowCount(), 0);
    }

    void taskSorting()
    {
        QStandardItemModel source(4, Akonadi::TodoModel::ColumnCount);
        const auto due = QDate(2099, 10, 2).startOfDay();
        for (int row = 0; row < 4; ++row) {
            auto todo = KCalendarCore::Todo::Ptr::create();
            todo->setSummary(QString::number(row));
            todo->setDtDue(due.addDays(row == 3 ? 1 : 0));
            todo->setPriority(row < 2 ? 0 : 1);
            for (int column = 0; column < source.columnCount(); ++column) {
                source.setData(source.index(row, column), QVariant::fromValue(todo), Akonadi::TodoModel::TodoPtrRole);
                source.setData(source.index(row, column), column == Akonadi::TodoModel::SummaryColumn ? QVariant(todo->summary()) : QVariant(0));
            }
        }
        TestTodoProxy proxy;
        proxy.setSourceModel(&source);
        for (const bool ascending : {true, false}) {
            proxy.setSortAscending(ascending);
            for (const int column : {Akonadi::TodoModel::PriorityColumn, Akonadi::TodoModel::DueDateColumn, Akonadi::TodoModel::PercentColumn}) {
                for (int left = 0; left < 4; ++left) {
                    QVERIFY(!proxy.lessThan(source.index(left, column), source.index(left, column)));
                    for (int right = 0; right < 4; ++right) {
                        const bool less = proxy.lessThan(source.index(left, column), source.index(right, column));
                        QVERIFY(!(less && proxy.lessThan(source.index(right, column), source.index(left, column))));
                        for (int third = 0; third < 4; ++third) {
                            if (less && proxy.lessThan(source.index(right, column), source.index(third, column))) {
                                QVERIFY(proxy.lessThan(source.index(left, column), source.index(third, column)));
                            }
                        }
                    }
                }
            }
        }
        proxy.setSortAscending(true);
        QVERIFY(proxy.lessThan(source.index(2, Akonadi::TodoModel::DueDateColumn), source.index(0, Akonadi::TodoModel::DueDateColumn)));
        QVERIFY(proxy.lessThan(source.index(2, Akonadi::TodoModel::PriorityColumn), source.index(3, Akonadi::TodoModel::PriorityColumn)));
        // Equal completion dates must fall through to the stable summary order.
        for (int row = 0; row < 4; ++row) {
            const auto todo = source.index(row, 0).data(Akonadi::TodoModel::TodoPtrRole).value<KCalendarCore::Todo::Ptr>();
            todo->setCompleted(due);
            source.setData(source.index(row, Akonadi::TodoModel::PercentColumn), 100);
        }
        QVERIFY(!proxy.lessThan(source.index(0, Akonadi::TodoModel::PercentColumn), source.index(0, Akonadi::TodoModel::PercentColumn)));
        QVERIFY(proxy.lessThan(source.index(0, Akonadi::TodoModel::PercentColumn), source.index(1, Akonadi::TodoModel::PercentColumn)));
        QVERIFY(!proxy.lessThan({}, {}));
    }
};

QTEST_GUILESS_MAIN(EditorModelsTest)
#include "editormodelstest.moc"
