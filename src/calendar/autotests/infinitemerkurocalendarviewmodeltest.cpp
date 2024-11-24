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

private Q_SLOTS:
    void testMonthDates()
    {
        InfiniteMerkuroCalendarViewModel model(this);

        QSignalSpy scaleSpy(&model, &InfiniteMerkuroCalendarViewModel::scaleChanged);
        QSignalSpy resetSpy(&model, &InfiniteMerkuroCalendarViewModel::modelReset);
        model.setScale(InfiniteMerkuroCalendarViewModel::Scale::MonthScale);
        QCOMPARE(scaleSpy.count(), 1);
        QCOMPARE(resetSpy.count(), 1);
    }
};

QTEST_MAIN(InfiniteMerkuroCalendarViewModelTest)
#include "infinitemerkurocalendarviewmodeltest.moc"
