// SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../utils.h"

#include <QTest>
using namespace Qt::Literals::StringLiterals;
class CalendarUtilsTest : public QObject
{
    Q_OBJECT

public:
    CalendarUtilsTest() = default;
    ~CalendarUtilsTest() override = default;

private:
    CalendarUtils utils;
    QLocale m_originalLocale;

private Q_SLOTS:
    void initTestCase()
    {
        m_originalLocale = QLocale();
        QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));
    }

    void cleanupTestCase()
    {
        QLocale::setDefault(m_originalLocale);
    }

    void testParseDateString()
    {
        QCOMPARE(utils.parseDateString(u"1/2/2025"_s).date(), QDate(2025, 1, 2));
        QCOMPARE(utils.parseDateString(u"1/2/26"_s).date(), QDate(2026, 1, 2));
        QVERIFY(!utils.parseDateString(u"2/30/26"_s).isValid());
        QVERIFY(!utils.parseDateString(u"not a date"_s).isValid());
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

    void testStartOfWeekMonday()
    {
        QLocale locale(QLocale::German);
        QCOMPARE(locale.firstDayOfWeek(), Qt::Monday);

        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 17), locale), QDate(2024, 1, 15));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 15), locale), QDate(2024, 1, 15));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 21), locale), QDate(2024, 1, 15));
    }

    void testStartOfWeekSunday()
    {
        QLocale locale(QLocale::English);
        QCOMPARE(locale.firstDayOfWeek(), Qt::Sunday);

        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 17), locale), QDate(2024, 1, 14));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 14), locale), QDate(2024, 1, 14));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 20), locale), QDate(2024, 1, 14));
    }

    void testStartOfWeekSaturday()
    {
        QLocale locale(QLocale::Arabic);
        QCOMPARE(locale.firstDayOfWeek(), Qt::Saturday);

        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 17), locale), QDate(2024, 1, 13));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 13), locale), QDate(2024, 1, 13));
        QCOMPARE(CalendarUtils::startOfWeek(QDate(2024, 1, 19), locale), QDate(2024, 1, 13));
    }
};

QTEST_MAIN(CalendarUtilsTest)
#include "calutilstest.moc"
