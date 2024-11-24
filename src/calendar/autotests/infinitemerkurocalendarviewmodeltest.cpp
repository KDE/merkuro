// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "models/infinitemerkurocalendarviewmodel.h"

#include <QAbstractItemModelTester>
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
        constexpr auto daysToLeftOfCenter = static_cast<int>(m_datesToAdd / 2);
        const auto firstDate = QDate::currentDate().addDays(-daysToLeftOfCenter);
        const auto firstIndex = model.index(0, 0);
        QCOMPARE(firstIndex.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate(), firstDate);

        for (auto i = 1; i < m_datesToAdd; ++i) {
            const auto index = model.index(i, 0);
            const auto startDate = index.data(InfiniteMerkuroCalendarViewModel::StartDateRole).toDate();
            const auto expectedStartDate = firstDate.addDays(i);
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
        constexpr auto monthsToLeftOfCenter = static_cast<int>(m_datesToAdd / 2);
        const auto firstDayOfFirstMonth = firstOfMonth.addMonths(-monthsToLeftOfCenter);
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
};

QTEST_MAIN(InfiniteMerkuroCalendarViewModelTest)
#include "infinitemerkurocalendarviewmodeltest.moc"
