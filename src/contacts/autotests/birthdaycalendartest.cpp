// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "birthdaycalendar.h"

#include <Akonadi/Collection>
#include <KCalendarCore/Event>
#include <QTest>

using namespace Qt::Literals::StringLiterals;

class BirthdayCalendarTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void usesBirthdayResourceEventsOnly()
    {
        Akonadi::Collection collection;
        collection.setRemoteId(u"akonadi_birthdays_resource"_s);

        const QDate birthday(2000, 1, 2);
        KCalendarCore::Event::Ptr event(new KCalendarCore::Event);
        event->setDtStart(QDateTime(birthday, QTime(0, 0)));
        event->setAllDay(true);
        event->setCustomProperty("KABC", "BIRTHDAY", u"YES"_s);

        Akonadi::Item item(KCalendarCore::Event::eventMimeType());
        item.setRemoteId(u"b42"_s);
        item.setPayload<KCalendarCore::Incidence::Ptr>(event);

        QCOMPARE(BirthdayCalendar::contactId(item, collection), 42);
        QCOMPARE(BirthdayCalendar::birthdayDate(item, collection), birthday);

        event->removeCustomProperty("KABC", "BIRTHDAY");
        QCOMPARE(BirthdayCalendar::contactId(item, collection), -1);
        event->setCustomProperty("KABC", "BIRTHDAY", u"YES"_s);

        item.setRemoteId(u"a42"_s);
        QCOMPARE(BirthdayCalendar::contactId(item, collection), -1);

        item.setRemoteId(u"b-invalid"_s);
        QCOMPARE(BirthdayCalendar::contactId(item, collection), -1);

        item.setRemoteId(u"b42"_s);
        collection.setRemoteId(u"other_calendar"_s);
        QCOMPARE(BirthdayCalendar::contactId(item, collection), -1);
    }
};

QTEST_GUILESS_MAIN(BirthdayCalendarTest)
#include "birthdaycalendartest.moc"
