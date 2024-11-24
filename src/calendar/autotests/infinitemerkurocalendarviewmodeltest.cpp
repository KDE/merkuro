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
    static constexpr int m_datesToAdd = 9;
    static constexpr int m_datesToLeftOfCenter = m_datesToAdd / 2;
    const QDate m_currentDate = QDate::currentDate();

private Q_SLOTS:
    void testDayDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::DayScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);

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
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::ThreeDayScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);

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

    void testMonthDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::MonthScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);

        const auto locale = QLocale::system();
        const auto generateFirstViewDateForFirstDayOfMonth = [&locale](const QDate &firstDayOfMonth) {
            const auto date = firstDayOfMonth.addDays(-firstDayOfMonth.dayOfWeek() + (locale.firstDayOfWeek() % 7));
            return date == firstDayOfMonth ? date.addDays(-7) : date;
        };

        const QDate firstOfMonth(m_currentDate.year(), m_currentDate.month(), 1);
        // We should dates to add / 2 both before and after the current months' first date
        const auto firstDayOfFirstMonth = firstOfMonth.addMonths(-m_datesToLeftOfCenter);
        const auto firstDateOfFirstMonthView = generateFirstViewDateForFirstDayOfMonth(firstDayOfFirstMonth);
        QCOMPARE(firstDateOfFirstMonthView.dayOfWeek(), locale.firstDayOfWeek());
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
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::YearScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);

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
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::DecadeScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
        QCOMPARE(model.rowCount(), m_datesToAdd);

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
        model.setDatesToAdd(m_datesToAdd);
        model.setScale(InfiniteMerkuroCalendarViewModel::DayScale);

        const auto currentRow = m_datesToLeftOfCenter + 1;
        const auto currentIndex = model.index(currentRow, 0);
        const auto currentDate = currentIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();

        const auto firstModelDate = model.index(0, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto lastModelDate = model.index(model.rowCount() - 1, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto rng = QRandomGenerator::global();

        const auto testMoveToDate = [&model](const QDate &selectedDate, const QDate &currentDate, const int currentRow) {
            const auto newIndex = model.moveToDate(selectedDate, currentDate, currentRow);
            const auto newDate = model.index(newIndex, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            return std::pair<int, QDate>{newIndex, newDate};
        };

        const QDate ungeneratedPastDate(rng->bounded(1500, firstModelDate.year() - 1),
                                        rng->bounded(firstModelDate.month() - 1, 12),
                                        rng->bounded(firstModelDate.day() - 1, 31));
        const QDate ungeneratedFutureDate(rng->bounded(lastModelDate.year() + 1, 2500),
                                          rng->bounded(lastModelDate.month() + 1, 12),
                                          rng->bounded(lastModelDate.day() + 1, 31));
        const QDate generatedDate(rng->bounded(ungeneratedPastDate.year() + 1, ungeneratedFutureDate.year() - 1), rng->bounded(1, 12), rng->bounded(1, 31));

        const auto move1 = testMoveToDate(ungeneratedPastDate, currentDate, currentRow);
        QCOMPARE(move1.second, ungeneratedPastDate);
        const auto move2 = testMoveToDate(ungeneratedFutureDate, ungeneratedPastDate, move1.first);
        QCOMPARE(move2.second, ungeneratedFutureDate);
        const auto move3 = testMoveToDate(generatedDate, ungeneratedFutureDate, move2.first);
        QCOMPARE(move3.second, generatedDate);
    }

    void testMoveThreeDay()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        model.setDatesToAdd(m_datesToAdd);
        model.setScale(InfiniteMerkuroCalendarViewModel::ThreeDayScale);

        const auto currentRow = m_datesToLeftOfCenter + 1;
        const auto currentIndex = model.index(currentRow, 0);
        const auto currentDate = currentIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();

        const auto firstModelDate = model.index(0, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto lastModelDate = model.index(model.rowCount() - 1, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
        const auto rng = QRandomGenerator::global();

        const auto testMoveToDate = [&model](const QDate &selectedDate, const QDate &currentDate, const int currentRow) {
            const auto newIndex = model.moveToDate(selectedDate, currentDate, currentRow);
            const auto newDate = model.index(newIndex, 0).data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            return std::pair<int, QDate>{newIndex, newDate};
        };
        const auto verifyMovedDate = [](const std::pair<int, QDate> &result, const QDate &selectedDate) {
            const auto startDateToSelectedDateDays = result.second.daysTo(selectedDate);
            QVERIFY(startDateToSelectedDateDays <= 2 && startDateToSelectedDateDays >= 0); // Should be no further than this
        };

        const QDate ungeneratedPastDate(rng->bounded(1500, firstModelDate.year() - 1),
                                        rng->bounded(std::min(firstModelDate.month() - 1, 1), 12),
                                        rng->bounded(std::min(firstModelDate.day() - 1, 1), 31));
        const QDate ungeneratedFutureDate(rng->bounded(lastModelDate.year() + 1, 2500), rng->bounded(1, 12), rng->bounded(1, 31));
        const QDate generatedDate(rng->bounded(ungeneratedPastDate.year() + 1, ungeneratedFutureDate.year() - 1), rng->bounded(1, 12), rng->bounded(1, 31));

        const auto move1 = testMoveToDate(ungeneratedPastDate, currentDate, currentRow);
        verifyMovedDate(move1, ungeneratedPastDate);
        const auto move2 = testMoveToDate(ungeneratedFutureDate, ungeneratedPastDate, move1.first);
        verifyMovedDate(move2, ungeneratedFutureDate);
        const auto move3 = testMoveToDate(generatedDate, ungeneratedFutureDate, move2.first);
        verifyMovedDate(move3, generatedDate);
    }
};

QTEST_MAIN(InfiniteMerkuroCalendarViewModelTest)
#include "infinitemerkurocalendarviewmodeltest.moc"
