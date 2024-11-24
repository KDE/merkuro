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
    void testMonthDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);
        model.setDatesToAdd(m_datesToAdd);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::MonthScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);

        const QDate firstOfMonth(m_currentDate.year(), m_currentDate.month(), 1);
        // We should dates to add / 2 both before and after the current months' first date
        constexpr auto monthsToLeftOfCenter = static_cast<int>(m_datesToAdd / 2);
        const auto firstDayOfFirstMonth = firstOfMonth.addMonths(-monthsToLeftOfCenter);
        QCOMPARE(model.index(0, 0).data(InfiniteMerkuroCalendarViewModel::FirstDayOfMonthRole).toDate(), firstDayOfFirstMonth);
    }
};

QTEST_MAIN(InfiniteMerkuroCalendarViewModelTest)
#include "infinitemerkurocalendarviewmodeltest.moc"
