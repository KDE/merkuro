// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <QByteArray>
#include <QObject>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/CollectionIdentificationAttribute>
#else
#include <AkonadiCore/CollectionIdentificationAttribute>
#endif
#include "attachmentsmodel.h"
#include "attendeesmodel.h"
#include "recurrenceexceptionsmodel.h"
#include "remindersmodel.h"

/**
 * This class is a wrapper for a KCalendarCore::Incidence::Ptr object.
 * We can use it to create new incidences, or create incidence pointers from
 * pre-existing incidences, to more cleanly pass around to our QML code
 * or to the CalendarManager, which handles the back-end stuff of
 * adding and editing the incidence in the collection of our choice.
 */

class IncidenceWrapper : public QObject, public KCalendarCore::IncidenceBase::IncidenceObserver
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr READ incidencePtr WRITE setIncidencePtr NOTIFY incidencePtrChanged)
    Q_PROPERTY(KCalendarCore::Incidence::Ptr originalIncidencePtr READ originalIncidencePtr NOTIFY originalIncidencePtrChanged)
    Q_PROPERTY(int incidenceType READ incidenceType NOTIFY incidenceTypeChanged)
    Q_PROPERTY(QString incidenceTypeStr READ incidenceTypeStr NOTIFY incidenceTypeStrChanged)
    Q_PROPERTY(QString incidenceIconName READ incidenceIconName NOTIFY incidenceIconNameChanged)
    Q_PROPERTY(QString uid READ uid CONSTANT);

    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QString parent READ parent WRITE setParent NOTIFY parentChanged)
    Q_PROPERTY(QString summary READ summary WRITE setSummary NOTIFY summaryChanged)
    Q_PROPERTY(QStringList categories READ categories WRITE setCategories NOTIFY categoriesChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(bool hasGeo READ hasGeo CONSTANT)
    Q_PROPERTY(float geoLatitude READ geoLatitude CONSTANT)
    Q_PROPERTY(float geoLongitude READ geoLongitude CONSTANT)

    Q_PROPERTY(QDateTime incidenceStart READ incidenceStart WRITE setIncidenceStart NOTIFY incidenceStartChanged)
    Q_PROPERTY(QString incidenceStartDateDisplay READ incidenceStartDateDisplay NOTIFY incidenceStartDateDisplayChanged)
    Q_PROPERTY(QString incidenceStartTimeDisplay READ incidenceStartTimeDisplay NOTIFY incidenceStartTimeDisplayChanged)
    Q_PROPERTY(QDateTime incidenceEnd READ incidenceEnd WRITE setIncidenceEnd NOTIFY incidenceEndChanged)
    Q_PROPERTY(QString incidenceEndDateDisplay READ incidenceEndDateDisplay NOTIFY incidenceEndDateDisplayChanged)
    Q_PROPERTY(QString incidenceEndTimeDisplay READ incidenceEndTimeDisplay NOTIFY incidenceEndTimeDisplayChanged)
    Q_PROPERTY(QByteArray timeZone READ timeZone WRITE setTimeZone NOTIFY timeZoneChanged)
    Q_PROPERTY(int startTimeZoneUTCOffsetMins READ startTimeZoneUTCOffsetMins NOTIFY startTimeZoneUTCOffsetMinsChanged)
    Q_PROPERTY(int endTimeZoneUTCOffsetMins READ endTimeZoneUTCOffsetMins NOTIFY endTimeZoneUTCOffsetMinsChanged)
    Q_PROPERTY(bool allDay READ allDay WRITE setAllDay NOTIFY allDayChanged)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged)

    Q_PROPERTY(KCalendarCore::Recurrence *recurrence READ recurrence NOTIFY incidencePtrChanged)
    Q_PROPERTY(QVariantMap recurrenceData READ recurrenceData NOTIFY recurrenceDataChanged)
    Q_PROPERTY(RecurrenceExceptionsModel *recurrenceExceptionsModel READ recurrenceExceptionsModel NOTIFY recurrenceExceptionsModelChanged)

    Q_PROPERTY(AttendeesModel *attendeesModel READ attendeesModel NOTIFY attendeesModelChanged)
    Q_PROPERTY(QVariantMap organizer READ organizer NOTIFY organizerChanged)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees NOTIFY attendeesChanged)

    Q_PROPERTY(RemindersModel *remindersModel READ remindersModel NOTIFY remindersModelChanged)
    Q_PROPERTY(AttachmentsModel *attachmentsModel READ attachmentsModel NOTIFY attachmentsModelChanged)

    Q_PROPERTY(bool todoCompleted READ todoCompleted WRITE setTodoCompleted NOTIFY todoCompletedChanged)
    Q_PROPERTY(QDateTime todoCompletionDt READ todoCompletionDt NOTIFY todoCompletionDtChanged)
    Q_PROPERTY(int todoPercentComplete READ todoPercentComplete WRITE setTodoPercentComplete NOTIFY todoPercentCompleteChanged)

public:
    enum RecurrenceIntervals {
        Daily,
        Weekly,
        Monthly,
        Yearly,
    };
    Q_ENUM(RecurrenceIntervals);

    enum IncidenceTypes {
        TypeEvent = KCalendarCore::IncidenceBase::TypeEvent,
        TypeTodo = KCalendarCore::IncidenceBase::TypeTodo,
        TypeJournal = KCalendarCore::IncidenceBase::TypeJournal,
    };
    Q_ENUM(IncidenceTypes)

    IncidenceWrapper(QObject *parent = nullptr);
    ~IncidenceWrapper() override;

    void incidenceUpdate(const QString &uid, const QDateTime &recurrenceId) override;
    void incidenceUpdated(const QString &uid, const QDateTime &recurrenceId) override;
    void notifyDataChanged();

    KCalendarCore::Incidence::Ptr incidencePtr() const;
    void setIncidencePtr(KCalendarCore::Incidence::Ptr incidencePtr);
    KCalendarCore::Incidence::Ptr originalIncidencePtr();
    int incidenceType() const;
    QString incidenceTypeStr() const;
    QString incidenceIconName() const;
    QString uid() const;
    qint64 collectionId() const;
    void setCollectionId(qint64 collectionId);
    QString parent() const;
    void setParent(QString parent);
    QString summary() const;
    void setSummary(const QString &summary);
    QStringList categories();
    void setCategories(QStringList categories);
    QString description() const;
    void setDescription(const QString &description);
    QString location() const;
    void setLocation(const QString &location);
    bool hasGeo() const;
    float geoLatitude() const;
    float geoLongitude() const;

    QDateTime incidenceStart() const;
    void setIncidenceStart(const QDateTime &incidenceStart, bool respectTimeZone = false);
    Q_INVOKABLE void setIncidenceStartDate(int day, int month, int year);
    Q_INVOKABLE void setIncidenceStartTime(int hours, int minutes);
    QString incidenceStartDateDisplay() const;
    QString incidenceStartTimeDisplay() const;
    QDateTime incidenceEnd() const;
    void setIncidenceEnd(const QDateTime &incidenceEnd, bool respectTimeZone = false);
    Q_INVOKABLE void setIncidenceEndDate(int day, int month, int year);
    Q_INVOKABLE void setIncidenceEndTime(int hours, int minutes);
    QString incidenceEndDateDisplay() const;
    QString incidenceEndTimeDisplay() const;
    QByteArray timeZone() const;
    void setTimeZone(const QByteArray &timeZone);
    int startTimeZoneUTCOffsetMins();
    int endTimeZoneUTCOffsetMins();
    bool allDay() const;
    void setAllDay(bool allDay);
    int priority() const;
    void setPriority(int priority);

    KCalendarCore::Recurrence *recurrence() const;
    QVariantMap recurrenceData();
    Q_INVOKABLE void setRecurrenceDataItem(const QString &key, const QVariant &value);

    QVariantMap organizer();
    KCalendarCore::Attendee::List attendees() const;

    RemindersModel *remindersModel();
    AttendeesModel *attendeesModel();
    RecurrenceExceptionsModel *recurrenceExceptionsModel();
    AttachmentsModel *attachmentsModel();

    bool todoCompleted();
    void setTodoCompleted(bool completed);
    QDateTime todoCompletionDt();
    int todoPercentComplete();
    void setTodoPercentComplete(int todoPercentComplete);

    Q_INVOKABLE void triggerEditMode();
    Q_INVOKABLE void setNewEvent();
    Q_INVOKABLE void setNewTodo();
    Q_INVOKABLE void addAlarms(KCalendarCore::Alarm::List alarms);
    Q_INVOKABLE void setRegularRecurrence(IncidenceWrapper::RecurrenceIntervals interval, int freq = 1);
    Q_INVOKABLE void setMonthlyPosRecurrence(short pos, int day);
    Q_INVOKABLE void setRecurrenceOccurrences(int occurrences);
    Q_INVOKABLE void clearRecurrences();

Q_SIGNALS:
    void incidenceChanged();
    void incidenceAboutToChange();
    void incidencePtrChanged(KCalendarCore::Incidence::Ptr incidencePtr);
    void originalIncidencePtrChanged();
    void incidenceTypeChanged();
    void incidenceTypeStrChanged();
    void incidenceIconNameChanged();
    void collectionIdChanged();
    void parentChanged();
    void summaryChanged();
    void categoriesChanged();
    void descriptionChanged();
    void locationChanged();
    void incidenceStartChanged();
    void incidenceStartDateDisplayChanged();
    void incidenceStartTimeDisplayChanged();
    void incidenceEndChanged();
    void incidenceEndDateDisplayChanged();
    void incidenceEndTimeDisplayChanged();
    void timeZoneChanged();
    void startTimeZoneUTCOffsetMinsChanged();
    void endTimeZoneUTCOffsetMinsChanged();
    void allDayChanged();
    void priorityChanged();
    void remindersModelChanged();
    void recurrenceDataChanged();
    void organizerChanged();
    void attendeesModelChanged();
    void recurrenceExceptionsModelChanged();
    void attachmentsModelChanged();
    void todoCompletedChanged();
    void todoCompletionDtChanged();
    void todoPercentCompleteChanged();
    void attendeesChanged();

private:
    KCalendarCore::Incidence::Ptr m_incidence;
    KCalendarCore::Incidence::Ptr m_originalIncidence;
    qint64 m_collectionId;
    RemindersModel m_remindersModel;
    AttendeesModel m_attendeesModel;
    RecurrenceExceptionsModel m_recurrenceExceptionsModel;
    AttachmentsModel m_attachmentsModel;
};
