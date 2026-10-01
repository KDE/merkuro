// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "incidencewrapper.h"
#include <Akonadi/TagCreateJob>
#include <KCalendarCore/Event>
#include <KCalendarCore/ICalFormat>
#include <KCalendarCore/Recurrence>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest/quicktest.h>
#include <akonadi/qtest_akonadi.h>

using namespace Qt::StringLiterals;

class QmlTestSetup : public QObject
{
    Q_OBJECT

    static KCalendarCore::Incidence::Ptr fixtureIncidence(IncidenceWrapper *wrapper, const QString &kind)
    {
        const KCalendarCore::Incidence::Ptr incidence(wrapper->incidencePtr()->clone());
        incidence->setDtStart(QDateTime(QDate(2026, 6, 11), QTime(9, 0), QTimeZone::UTC));
        if (const auto event = incidence.dynamicCast<KCalendarCore::Event>()) {
            event->setDtEnd(incidence->dtStart().addSecs(3600));
        }
        incidence->setAllDay(false);
        incidence->setDescription(u"Fixture notes"_s);
        incidence->setCategories({u"Editor category"_s});
        incidence->setAttendees({KCalendarCore::Attendee(u"Fixture attendee"_s, u"fixture@example.org"_s, true, KCalendarCore::Attendee::Accepted)});
        auto recurrence = incidence->recurrence();
        recurrence->clear();
        if (kind == u"weekly") {
            recurrence->setWeekly(3);
            QBitArray weekdays(7);
            weekdays.setBit(0);
            weekdays.setBit(4);
            recurrence->addWeeklyDays(weekdays);
        } else if (kind == u"monthly-position") {
            recurrence->setMonthly(2);
            recurrence->setMonthlyPos({KCalendarCore::RecurrenceRule::WDayPos(2, 4)});
        } else if (kind == u"monthly-date") {
            recurrence->setMonthly(2);
            recurrence->setMonthlyDate({11, 25});
        } else if (kind == u"yearly") {
            recurrence->setYearly(4);
            recurrence->setYearlyMonth({2, 11});
            recurrence->setYearlyDate({3, 15});
        } else if (kind == u"hourly") {
            recurrence->setHourly(2);
        } else {
            recurrence->setDaily(2);
        }
        if (kind == u"end-date") {
            recurrence->setEndDateTime(QDateTime(QDate(2026, 12, 11), QTime(9, 0), QTimeZone::UTC));
        } else {
            recurrence->setDuration(9);
        }
        recurrence->addExDate(QDate(2026, 7, 11));
        return incidence;
    }

public Q_SLOTS:
    void setEditorFixture(IncidenceWrapper *wrapper, const QString &kind)
    {
        auto item = wrapper->incidenceItem();
        item.setPayload<KCalendarCore::Incidence::Ptr>(fixtureIncidence(wrapper, kind));
        wrapper->setIncidenceItem(item);
    }

    QString updateEditorFixture(IncidenceWrapper *wrapper, const QString &kind)
    {
        auto item = wrapper->incidenceItem();
        item.setRevision(item.revision() + 1);
        const auto incidence = fixtureIncidence(wrapper, kind);
        item.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
        wrapper->recordExternalChange(item);
        KCalendarCore::ICalFormat format;
        return format.toString(incidence);
    }

    QString draftContents(IncidenceWrapper *wrapper)
    {
        KCalendarCore::ICalFormat format;
        return format.toString(wrapper->incidencePtr());
    }

    void prepareEditor(IncidenceWrapper *wrapper)
    {
        Akonadi::Item item(999999);
        item.setRevision(0);
        item.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(wrapper->incidencePtr()->clone()));
        wrapper->setIncidenceItem(item);
        wrapper->triggerEditMode();
    }

    void updateEditor(IncidenceWrapper *wrapper, const QString &summary)
    {
        auto item = wrapper->incidenceItem();
        item.setRevision(item.revision() + 1);
        const KCalendarCore::Incidence::Ptr incidence(item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        incidence->setSummary(summary);
        item.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
        wrapper->recordExternalChange(item);
    }

    void removeEditor(IncidenceWrapper *wrapper)
    {
        wrapper->recordRemoval();
    }

    void applicationAvailable()
    {
        AkonadiTest::checkTestIsIsolated();
        KLocalizedString::setApplicationDomain("merkuro");
        Akonadi::TagCreateJob tag(Akonadi::Tag::genericTag(u"Editor category"_s));
        tag.setAutoDelete(false);
        if (!tag.exec()) {
            qFatal("Failed to create editor test tag: %s", qPrintable(tag.errorString()));
        }
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        KLocalization::setupLocalizedContext(engine);
        engine->rootContext()->setContextProperty(QStringLiteral("editorTestHelper"), this);
    }
};

QUICK_TEST_MAIN_WITH_SETUP(CalendarQmlTests, QmlTestSetup)

#include "qmltestrunner.moc"
