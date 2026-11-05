// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KCalendarCore/Event>
#include <KCalendarCore/ScheduleMessage>
#include <QObject>
#include <QPointer>
#include <QQmlEngine>
#include <QUrl>

class InvitationResponseJob;

class CalendarInvitation : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString content READ content WRITE setContent NOTIFY contentChanged)
    Q_PROPERTY(bool responseRequested READ responseRequested NOTIFY contentChanged)
    Q_PROPERTY(QStringList responseAddresses READ responseAddresses NOTIFY responseAddressesChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY responseStateChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY responseStateChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY responseStateChanged)
    Q_PROPERTY(QString replyStatusMessage READ replyStatusMessage NOTIFY contentChanged)
    Q_PROPERTY(bool replyDeclined READ replyDeclined NOTIFY contentChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY contentChanged)
    Q_PROPERTY(bool allDay READ allDay NOTIFY contentChanged)
    Q_PROPERTY(bool canceled READ canceled NOTIFY contentChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY contentChanged)
    Q_PROPERTY(QString organizer READ organizer NOTIFY contentChanged)
    Q_PROPERTY(QString location READ location NOTIFY contentChanged)
    Q_PROPERTY(QUrl locationUrl READ locationUrl NOTIFY contentChanged)
    Q_PROPERTY(QString description READ description NOTIFY contentChanged)
    Q_PROPERTY(QString dateTimeRange READ dateTimeRange NOTIFY contentChanged)
    Q_PROPERTY(QString startTime READ startTime NOTIFY contentChanged)
    Q_PROPERTY(QString endTime READ endTime NOTIFY contentChanged)
    Q_PROPERTY(QStringList attendees READ attendees NOTIFY contentChanged)

public:
    explicit CalendarInvitation(QObject *parent = nullptr);

    QString content() const;
    void setContent(const QString &content);
    bool responseRequested() const;
    QStringList responseAddresses() const;
    QStringList matchingResponseAddresses(const QStringList &emails) const;
    KCalendarCore::Event::Ptr responseEvent(const QString &receiver, bool accept) const;
    bool busy() const;
    QString errorString() const;
    QString statusMessage() const;
    QString replyStatusMessage() const;
    bool replyDeclined() const;
    Q_INVOKABLE void respond(const QString &receiver, bool accept);

    bool isValid() const;
    bool allDay() const;
    bool canceled() const;
    QString summary() const;
    QString organizer() const;
    QString location() const;
    QUrl locationUrl() const;
    QString description() const;
    QString dateTimeRange() const;
    QString startTime() const;
    QString endTime() const;
    QStringList attendees() const;

Q_SIGNALS:
    void contentChanged();
    void responseStateChanged();
    void responseAddressesChanged();

private:
    QString m_content;
    QString m_errorString;
    QString m_statusMessage;
    QPointer<InvitationResponseJob> m_responseJob;
    KCalendarCore::ScheduleMessage::Ptr m_schedule;
    bool m_canceled = false;
    KCalendarCore::Event::Ptr m_event;
};
