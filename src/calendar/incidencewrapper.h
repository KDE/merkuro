// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "calendarmanager.h"
#include "models/attachmentsmodel.h"
#include "models/attendeesmodel.h"
#include "models/recurrenceexceptionsmodel.h"

#include <Akonadi/CollectionIdentificationAttribute>
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemMonitor>
#include <KCalUtils/RecurrenceActions>
#include <KFormat>
#include <QByteArray>
#include <QObject>
#include <QPointer>
#include <qqmlintegration.h>

class MonthPosition
{
    Q_GADGET
    Q_PROPERTY(int day MEMBER day)
    Q_PROPERTY(int pos MEMBER pos)

public:
    int day;
    int pos;

    bool operator==(const MonthPosition &rhs) const
    {
        return day == rhs.day && pos == rhs.pos;
    }
};

class RecurrenceData
{
    Q_GADGET
    Q_PROPERTY(QList<bool> weekdays MEMBER weekdays)
    Q_PROPERTY(int duration MEMBER duration)
    Q_PROPERTY(int frequency MEMBER frequency)
    Q_PROPERTY(QDateTime startDateTime MEMBER startDateTime)
    Q_PROPERTY(QString startDateTimeDisplay MEMBER startDateTimeDisplay)
    Q_PROPERTY(QDateTime endDateTime MEMBER endDateTime)
    Q_PROPERTY(QString endDateTimeDisplay MEMBER endDateTimeDisplay)
    Q_PROPERTY(QString endDateDisplay MEMBER endDateDisplay)
    Q_PROPERTY(bool allDay MEMBER allDay)
    Q_PROPERTY(ushort type MEMBER type)
    Q_PROPERTY(QList<int> monthDays MEMBER monthDays)
    Q_PROPERTY(QList<MonthPosition> monthPositions MEMBER monthPositions)
    Q_PROPERTY(QList<int> yearDays MEMBER yearDays)
    Q_PROPERTY(QList<int> yearDates MEMBER yearDates)
    Q_PROPERTY(QList<int> yearMonths MEMBER yearMonths)

public:
    QList<bool> weekdays;
    int duration;
    int frequency;
    QDateTime startDateTime;
    QString startDateTimeDisplay;
    QDateTime endDateTime;
    QString endDateTimeDisplay;
    QString endDateDisplay;
    bool allDay;
    ushort type;
    QList<int> monthDays;
    QList<MonthPosition> monthPositions;
    QList<int> yearDays;
    QList<int> yearDates;
    QList<int> yearMonths;
};

/**
 * This class is a wrapper for a KCalendarCore::Incidence::Ptr object.
 * We can use it to create new incidences, or create incidence pointers from
 * pre-existing incidences, to more cleanly pass around to our QML code
 * or to the CalendarManager, which handles the back-end stuff of
 * adding and editing the incidence in the collection of our choice.
 */

class IncidenceWrapper : public QObject, public Akonadi::ItemMonitor
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

    // Akonadi properties
    Q_PROPERTY(Akonadi::Item incidenceItem READ incidenceItem WRITE setIncidenceItem NOTIFY incidenceItemChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)

    // Incidence properties
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr READ incidencePtr WRITE setIncidencePtr NOTIFY incidencePtrChanged)
    Q_PROPERTY(KCalendarCore::Incidence::Ptr originalIncidencePtr READ originalIncidencePtr NOTIFY originalIncidencePtrChanged)
    Q_PROPERTY(int incidenceType READ incidenceType NOTIFY incidenceTypeChanged)
    Q_PROPERTY(QString incidenceTypeStr READ incidenceTypeStr NOTIFY incidenceTypeStrChanged)
    Q_PROPERTY(QString incidenceIconName READ incidenceIconName NOTIFY incidenceIconNameChanged)
    Q_PROPERTY(QString uid READ uid CONSTANT) // TODO: This needs to not be a CONSTANT

    Q_PROPERTY(QString parent READ parent WRITE setParent NOTIFY parentChanged)
    Q_PROPERTY(IncidenceWrapper *parentIncidence READ parentIncidence NOTIFY parentIncidenceChanged)
    Q_PROPERTY(QVariantList childIncidences READ childIncidences NOTIFY childIncidencesChanged)

    Q_PROPERTY(QString summary READ summary WRITE setSummary NOTIFY summaryChanged)
    Q_PROPERTY(QStringList categories READ categories WRITE setCategories NOTIFY categoriesChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QString location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(bool hasGeo READ hasGeo CONSTANT) // TODO: This needs to not be a CONSTANT
    Q_PROPERTY(float geoLatitude READ geoLatitude CONSTANT) // TODO: This needs to not be a CONSTANT
    Q_PROPERTY(float geoLongitude READ geoLongitude CONSTANT) // TODO: This needs to not be a CONSTANT

    Q_PROPERTY(QDateTime incidenceStart READ incidenceStart WRITE setIncidenceStart NOTIFY incidenceStartChanged)
    Q_PROPERTY(QString incidenceStartDateDisplay READ incidenceStartDateDisplay NOTIFY incidenceStartDateDisplayChanged)
    Q_PROPERTY(QString incidenceStartTimeDisplay READ incidenceStartTimeDisplay NOTIFY incidenceStartTimeDisplayChanged)
    Q_PROPERTY(QDateTime incidenceEnd READ incidenceEnd WRITE setIncidenceEnd NOTIFY incidenceEndChanged)
    Q_PROPERTY(QString incidenceEndDateDisplay READ incidenceEndDateDisplay NOTIFY incidenceEndDateDisplayChanged)
    Q_PROPERTY(QString incidenceEndTimeDisplay READ incidenceEndTimeDisplay NOTIFY incidenceEndTimeDisplayChanged)
    Q_PROPERTY(QByteArray timeZone READ timeZone WRITE setTimeZone NOTIFY timeZoneChanged)
    Q_PROPERTY(int startTimeZoneUTCOffsetMins READ startTimeZoneUTCOffsetMins NOTIFY startTimeZoneUTCOffsetMinsChanged)
    Q_PROPERTY(int endTimeZoneUTCOffsetMins READ endTimeZoneUTCOffsetMins NOTIFY endTimeZoneUTCOffsetMinsChanged)
    Q_PROPERTY(KCalendarCore::Duration duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString durationDisplayString READ durationDisplayString NOTIFY durationDisplayStringChanged)
    Q_PROPERTY(bool allDay READ allDay WRITE setAllDay NOTIFY allDayChanged)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged)

    Q_PROPERTY(KCalendarCore::Recurrence *recurrence READ recurrence NOTIFY incidencePtrChanged)
    Q_PROPERTY(RecurrenceData recurrenceData READ recurrenceData NOTIFY recurrenceDataChanged)
    Q_PROPERTY(RecurrenceExceptionsModel *recurrenceExceptionsModel READ recurrenceExceptionsModel NOTIFY recurrenceExceptionsModelChanged)

    Q_PROPERTY(AttendeesModel *attendeesModel READ attendeesModel NOTIFY attendeesModelChanged)
    Q_PROPERTY(QVariantMap organizer READ organizer NOTIFY organizerChanged)
    Q_PROPERTY(KCalendarCore::Attendee::List attendees READ attendees NOTIFY attendeesChanged)

    Q_PROPERTY(AttachmentsModel *attachmentsModel READ attachmentsModel NOTIFY attachmentsModelChanged)

    Q_PROPERTY(bool todoCompleted READ todoCompleted WRITE setTodoCompleted NOTIFY todoCompletedChanged)
    Q_PROPERTY(QDateTime todoCompletionDt READ todoCompletionDt NOTIFY todoCompletionDtChanged)
    Q_PROPERTY(int todoPercentComplete READ todoPercentComplete WRITE setTodoPercentComplete NOTIFY todoPercentCompleteChanged)

    Q_PROPERTY(QString googleConferenceUrl READ googleConferenceUrl NOTIFY googleConferenceUrlChanged)

public:
    enum RecurrenceIntervals {
        Daily,
        Weekly,
        Monthly,
        Yearly,
    };
    Q_ENUM(RecurrenceIntervals)

    enum IncidenceTypes {
        TypeEvent = KCalendarCore::IncidenceBase::TypeEvent,
        TypeTodo = KCalendarCore::IncidenceBase::TypeTodo,
        TypeJournal = KCalendarCore::IncidenceBase::TypeJournal,
    };
    Q_ENUM(IncidenceTypes)

    enum RecurrenceActions {
        AllOccurrences = KCalUtils::RecurrenceActions::AllOccurrences,
        SelectedOccurrence = KCalUtils::RecurrenceActions::SelectedOccurrence,
        FutureOccurrences = KCalUtils::RecurrenceActions::FutureOccurrences,
    };
    Q_ENUM(RecurrenceActions)

    typedef QSharedPointer<IncidenceWrapper> Ptr;

    explicit IncidenceWrapper(CalendarManager *CalendarManager, QObject *parent = nullptr);
    ~IncidenceWrapper() override;

    void notifyDataChanged();

    [[nodiscard]] Akonadi::Item incidenceItem() const;
    void setIncidenceItem(const Akonadi::Item &incidenceItem);
    KCalendarCore::Incidence::Ptr incidencePtr() const;
    KCalendarCore::Incidence::Ptr originalIncidencePtr();
    [[nodiscard]] int incidenceType() const;
    [[nodiscard]] QString incidenceTypeStr() const;
    [[nodiscard]] QString incidenceIconName() const;
    [[nodiscard]] QString uid() const;
    [[nodiscard]] qint64 collectionId() const;
    void setCollectionId(qint64 collectionId);
    [[nodiscard]] QString parent() const;
    void setParent(const QString &parent);
    IncidenceWrapper *parentIncidence();
    QVariantList childIncidences();

    [[nodiscard]] QString summary() const;
    void setSummary(const QString &summary);
    [[nodiscard]] QStringList categories();
    void setCategories(const QStringList &categories);
    [[nodiscard]] QString description() const;
    void setDescription(const QString &description);
    [[nodiscard]] QString location() const;
    void setLocation(const QString &location);
    [[nodiscard]] bool hasGeo() const;
    [[nodiscard]] float geoLatitude() const;
    [[nodiscard]] float geoLongitude() const;

    [[nodiscard]] QDateTime incidenceStart() const;
    Q_INVOKABLE void setIncidenceStart(const QDateTime &incidenceStart, bool respectTimeZone = false);
    Q_INVOKABLE void setIncidenceStartDate(int day, int month, int year);
    Q_INVOKABLE void setIncidenceStartTime(int hours, int minutes);
    [[nodiscard]] QString incidenceStartDateDisplay() const;
    [[nodiscard]] QString incidenceStartTimeDisplay() const;
    [[nodiscard]] QDateTime incidenceEnd() const;
    Q_INVOKABLE void setIncidenceEnd(const QDateTime &incidenceEnd, bool respectTimeZone = false);
    Q_INVOKABLE void setIncidenceEndDate(int day, int month, int year);
    Q_INVOKABLE void setIncidenceEndTime(int hours, int minutes);
    [[nodiscard]] QString incidenceEndDateDisplay() const;
    [[nodiscard]] QString incidenceEndTimeDisplay() const;
    Q_INVOKABLE void setIncidenceTimeToNearestQuarterHour(bool setStartTime = true, bool setEndTime = true);
    [[nodiscard]] QByteArray timeZone() const;
    void setTimeZone(const QByteArray &timeZone);
    [[nodiscard]] int startTimeZoneUTCOffsetMins();
    [[nodiscard]] int endTimeZoneUTCOffsetMins();
    [[nodiscard]] KCalendarCore::Duration duration() const;
    [[nodiscard]] QString durationDisplayString() const;
    [[nodiscard]] bool allDay() const;
    void setAllDay(bool allDay);
    [[nodiscard]] int priority() const;
    void setPriority(int priority);

    KCalendarCore::Recurrence *recurrence() const;
    RecurrenceData recurrenceData() const;
    Q_INVOKABLE void setRecurrenceDataItem(const QString &key, const QVariant &value);

    QVariantMap organizer();
    [[nodiscard]] KCalendarCore::Attendee::List attendees() const;

    AttendeesModel *attendeesModel();
    RecurrenceExceptionsModel *recurrenceExceptionsModel();
    AttachmentsModel *attachmentsModel();

    [[nodiscard]] bool todoCompleted() const;
    void setTodoCompleted(bool completed);
    [[nodiscard]] QDateTime todoCompletionDt();
    [[nodiscard]] int todoPercentComplete() const;
    void setTodoPercentComplete(int todoPercentComplete);

    Q_INVOKABLE void triggerEditMode();
    Q_INVOKABLE void setNewEvent();
    Q_INVOKABLE void setNewTodo();
    Q_INVOKABLE void addAlarms(const KCalendarCore::Alarm::List &alarms);
    Q_INVOKABLE bool hasReminders() const;
    Q_INVOKABLE void setRegularRecurrence(IncidenceWrapper::RecurrenceIntervals interval, int freq = 1);
    Q_INVOKABLE void setMonthlyPosRecurrence(short pos, int day);
    Q_INVOKABLE void setRecurrenceOccurrences(int occurrences);
    Q_INVOKABLE void clearRecurrences();

    Q_INVOKABLE void setCollection(const Akonadi::Collection &collection);

    [[nodiscard]] QString googleConferenceUrl();
Q_SIGNALS:
    void incidenceItemChanged();
    void incidencePtrChanged(KCalendarCore::Incidence::Ptr incidencePtr);
    void originalIncidencePtrChanged();
    void incidenceTypeChanged();
    void incidenceTypeStrChanged();
    void incidenceIconNameChanged();
    void collectionIdChanged();
    void parentChanged();
    void parentIncidenceChanged();
    void childIncidencesChanged();

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
    void durationChanged();
    void durationDisplayStringChanged();
    void allDayChanged();
    void priorityChanged();

    void recurrenceDataChanged();
    void organizerChanged();
    void attendeesModelChanged();
    void recurrenceExceptionsModelChanged();
    void attachmentsModelChanged();

    void todoCompletedChanged();
    void todoCompletionDtChanged();
    void todoPercentCompleteChanged();
    void attendeesChanged();

    void googleConferenceUrlChanged();

protected:
    void itemChanged(const Akonadi::Item &item) override;

private:
    void setIncidencePtr(KCalendarCore::Incidence::Ptr incidencePtr);
    void setNewIncidence(KCalendarCore::Incidence::Ptr incidence);
    void updateParentIncidence();
    void resetChildIncidences();
    void cleanupChildIncidences();

    QPointer<CalendarManager> m_calendarManager = nullptr;

    KCalendarCore::Incidence::Ptr m_incidence;
    KCalendarCore::Incidence::Ptr m_originalIncidence;
    qint64 m_collectionId = -1; // For when we want to edit, this is temporary
    AttendeesModel m_attendeesModel;
    RecurrenceExceptionsModel m_recurrenceExceptionsModel;
    AttachmentsModel m_attachmentsModel;

    KFormat m_format;
    Ptr m_parentIncidence;
    QVariantList m_childIncidences;
};
