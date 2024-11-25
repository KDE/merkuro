// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "models/infinitemerkurocalendarviewmodel.h"

#include <QAbstractItemModelTester>
#include <QRandomGenerator>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>

class InfiniteMerkuroCalendarViewModelTest : public QObject
{
    Q_OBJECT

public:
    InfiniteMerkuroCalendarViewModelTest() = default;
    ~InfiniteMerkuroCalendarViewModelTest() override = default;

private:
    struct MoveTestDates {
        QDate ungeneratedPast;
        QDate ungeneratedFuture;
        QDate generated;
    };

    static struct MoveTestDates generatedMoveDates(const InfiniteMerkuroCalendarViewModel &model)
    {
        const auto firstModelDate = model.index(0, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto lastModelDate = model.index(model.rowCount() - 1, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto rng = QRandomGenerator::global();

        const QCalendar calendar;
        const auto maximumMonthsInYear = calendar.maximumMonthsInYear();

        const auto pastYear = rng->bounded(m_genDatesLower, firstModelDate.year() - 1);
        const auto pastMonth = rng->bounded(std::max(firstModelDate.month() - 1, 1), maximumMonthsInYear);
        const auto pastDay = rng->bounded(std::max(firstModelDate.day() - 1, 1), QDate(pastYear, pastMonth, 1).daysInMonth(calendar));
        const QDate ungeneratedPastDate(pastYear, pastMonth, pastDay);

        const auto futureYear = rng->bounded(lastModelDate.year() + 1, m_genDatesUpper);
        const auto futureMonth = rng->bounded(1, maximumMonthsInYear);
        const auto futureDay = rng->bounded(1, QDate(futureYear, futureMonth, 1).daysInMonth(calendar));
        const QDate ungeneratedFutureDate(futureYear, futureMonth, futureDay);

        const auto alreadyGeneratedYear = rng->bounded(ungeneratedPastDate.year() + 1, ungeneratedFutureDate.year() - 1);
        const auto alreadyGeneratedMonth = rng->bounded(1, maximumMonthsInYear);
        const auto alreadyGeneratedDay = rng->bounded(1, QDate(alreadyGeneratedYear, alreadyGeneratedMonth, 1).daysInMonth(calendar));
        const QDate generatedDate(alreadyGeneratedYear, alreadyGeneratedMonth, alreadyGeneratedDay);

        return {.ungeneratedPast = ungeneratedPastDate, .ungeneratedFuture = ungeneratedFutureDate, .generated = generatedDate};
    }

    static std::pair<int, QDate>
    moveToDateResult(InfiniteMerkuroCalendarViewModel &model, const QDate &selectedDate, const QDate &currentDate, const int currentRow)
    {
        const auto newIndex = model.moveToDate(selectedDate, currentDate, currentRow);
        const auto newDate = model.index(newIndex, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        return {newIndex, newDate};
    };

    static QDate firstWeekDayDateForDate(const QDate &date)
    {
        return date.addDays(-date.dayOfWeek() + (QLocale::system().firstDayOfWeek() % 7));
    }

    static void genericMoveTest(InfiniteMerkuroCalendarViewModel &model, std::function<void(std::pair<int, QDate>, QDate)> moveVerifyingFunc)
    {
        const auto currentRow = m_datesToLeftOfCenter + 1;
        const auto currentIndex = model.index(currentRow, 0);
        const auto currentDate = currentIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto testDates = generatedMoveDates(model);

        const auto move1 = moveToDateResult(model, testDates.ungeneratedPast, currentDate, currentRow);
        moveVerifyingFunc(move1, testDates.ungeneratedPast);
        const auto move2 = moveToDateResult(model, testDates.ungeneratedFuture, testDates.ungeneratedPast, move1.first);
        moveVerifyingFunc(move2, testDates.ungeneratedFuture);
        const auto move3 = moveToDateResult(model, testDates.generated, testDates.ungeneratedFuture, move2.first);
        moveVerifyingFunc(move3, testDates.generated);
    }

    static void setupModel(InfiniteMerkuroCalendarViewModel &model, const InfiniteMerkuroCalendarViewModel::Scale scale)
    {
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(scale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);
    }

    static constexpr int m_datesToAdd = 9;
    static constexpr int m_datesToLeftOfCenter = m_datesToAdd / 2;
    static constexpr int m_genDatesUpper = 2200;
    static constexpr int m_genDatesLower = 1800;
    const QDate m_currentDate = QDate::currentDate();

private Q_SLOTS:
    void testDayDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::DayScale);

        // We should dates to add / 2 both before and after the current date
        const auto firstDate = QDate::currentDate().addDays(-m_datesToLeftOfCenter);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstDate.addDays(i);
            QCOMPARE(startDate, expectedStartDate);
        }
    }

    void testThreeDayDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::ThreeDayScale);

        // We should dates to add / 2 both before and after the current date
        constexpr auto daysToLeftOfCenter = static_cast<int>(m_datesToAdd * 3 / 2);
        const auto firstDate = QDate::currentDate().addDays(-daysToLeftOfCenter);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstDate.addDays(i * 3);
            QCOMPARE(startDate, expectedStartDate);
        }
    }

    void testWeekDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::WeekScale);

        const auto currentStartOfWeek = firstWeekDayDateForDate(QDate::currentDate());
        constexpr auto weeksToLeftOfCenter = static_cast<int>(m_datesToAdd / 2);
        const auto firstDate = currentStartOfWeek.addDays(-weeksToLeftOfCenter * 7);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstDate.addDays(i * 7);
            QCOMPARE(startDate, expectedStartDate);
        }
    }

    void testMonthDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::MonthScale);

        const auto generateFirstViewDateForFirstDayOfMonth = [](const QDate &firstDayOfMonth) {
            const auto date = firstWeekDayDateForDate(firstDayOfMonth);
            return date == firstDayOfMonth ? date.addDays(-7) : date;
        };

        const QDate firstOfMonth(m_currentDate.year(), m_currentDate.month(), 1);
        // We should dates to add / 2 both before and after the current months' first date
        const auto firstDayOfFirstMonth = firstOfMonth.addMonths(-m_datesToLeftOfCenter);
        const auto firstDateOfFirstMonthView = generateFirstViewDateForFirstDayOfMonth(firstDayOfFirstMonth);
        QCOMPARE(firstDateOfFirstMonthView.dayOfWeek(), QLocale::system().firstDayOfWeek());
        QVERIFY(firstDateOfFirstMonthView < firstDayOfFirstMonth);

        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::FirstDayOfMonthRole).toDate(), firstDayOfFirstMonth);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDateOfFirstMonthView);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto firstDayOfMonth = index.data(InfiniteMerkuroCalendarViewModel::FirstDayOfMonthRole).toDate();
            const auto firstDayOfMonthView = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedFirstDayOfMonth = firstDayOfFirstMonth.addMonths(i);
            const auto expectedFirstDateOfMonthView = generateFirstViewDateForFirstDayOfMonth(expectedFirstDayOfMonth);
            QCOMPARE(firstDayOfMonth, expectedFirstDayOfMonth);
            QCOMPARE(firstDayOfMonthView, expectedFirstDateOfMonthView);
        }
    }

    void testYearDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::YearScale);

        // We should dates to add / 2 both before and after the current date
        const auto currentDate = QDate::currentDate();
        const auto firstYearDate = QDate(currentDate.year() - m_datesToLeftOfCenter, currentDate.month(), 1);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstYearDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstYearDate.addYears(i);
            QCOMPARE(startDate, expectedStartDate);
        }
    }

    void testDecadeDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::DecadeScale);

        // We should dates to add / 2 both before and after the current date
        const auto currentDate = QDate::currentDate();
        const auto currentDecadeFloor = (currentDate.year() / 10) * 10 - 1; // 4*4 grid shows the decade as well as -1 & +1 years
        const auto currentDecadeFloorDate = QDate(currentDecadeFloor, currentDate.month(), 1);
        const auto firstDecadeDate = QDate(currentDecadeFloorDate.year() - m_datesToLeftOfCenter * 10, currentDate.month(), 1);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDecadeDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstDecadeDate.addYears(i * 10);
            QCOMPARE(startDate, expectedStartDate);
        }
    }

    void testMoveDay()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::DayScale);

        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            QCOMPARE(result.second, selectedDate);
        };

        genericMoveTest(model, verifyMovedDate);
    }

    void testMoveThreeDay()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::ThreeDayScale);

        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            const auto startDateToSelectedDateDays = result.second.daysTo(selectedDate);
            QVERIFY(startDateToSelectedDateDays <= 2 && startDateToSelectedDateDays >= 0); // Should be no further than this
        };

        genericMoveTest(model, verifyMovedDate);
    }

    void testMoveWeek()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::WeekScale);

        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            const auto startDate = result.second;
            QCOMPARE(startDate.dayOfWeek(), QLocale::system().firstDayOfWeek());
            const auto startDateToSelectedDateDays = startDate.daysTo(selectedDate);
            QVERIFY(startDateToSelectedDateDays <= 6 && startDateToSelectedDateDays >= 0); // Should be no further than this
        };

        genericMoveTest(model, verifyMovedDate);
    }

    void testMoveMonth()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::MonthScale);

        const auto verifyMovedDate = [&model](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            const auto firstDayOfMonth = model.index(result.first, 0).data(InfiniteMerkuroCalendarViewModel::FirstDayOfMonthRole).toDate();
            QCOMPARE(firstDayOfMonth, QDate(selectedDate.year(), selectedDate.month(), 1));
        };

        genericMoveTest(model, verifyMovedDate);
    }

    void testMoveYear()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::YearScale);

        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            QCOMPARE(result.second.year(), selectedDate.year());
        };

        genericMoveTest(model, verifyMovedDate);
    }

    void testMoveDecade()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        setupModel(model, InfiniteMerkuroCalendarViewModel::DecadeScale);

        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            const auto firstDecadeYear = selectedDate.year() / 10 * 10;
            qDebug() << selectedDate << firstDecadeYear << result.second.year();
            QCOMPARE(result.second.year(), firstDecadeYear - 1); // Since we display 12, decade -1 and +1
        };

        genericMoveTest(model, verifyMovedDate);
    }
};

QTEST_MAIN(InfiniteMerkuroCalendarViewModelTest)
#include "infinitemerkurocalendarviewmodeltest.moc"
