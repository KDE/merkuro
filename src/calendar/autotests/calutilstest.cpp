// SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../utils.h"

#include <QSignalSpy>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class CalendarUtilsTest : public QObject
{
    Q_OBJECT

public:
    CalendarUtilsTest() = default;
    ~CalendarUtilsTest() override = default;

private:
    Utils utils;

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testRemindersLabel()
    {
        QCOMPARE(utils.secondsToReminderLabel(0), u"On event start"_s);

        QCOMPARE(utils.secondsToReminderLabel(300), u"5 minutes after start of event"_s);
        QCOMPARE(utils.secondsToReminderLabel(7200), u"2 hours after start of event"_s);
        QCOMPARE(utils.secondsToReminderLabel(259200), u"3 days after start of event"_s);

        QCOMPARE(utils.secondsToReminderLabel(-300), u"5 minutes before start of event"_s);
        QCOMPARE(utils.secondsToReminderLabel(-7200), u"2 hours before start of event"_s);
        QCOMPARE(utils.secondsToReminderLabel(-259200), u"3 days before start of event"_s);
    }
};

QTEST_MAIN(CalendarUtilsTest)
#include "calutilstest.moc"
