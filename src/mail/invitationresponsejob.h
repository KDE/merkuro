// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KCalendarCore/Event>
#include <KCalendarCore/ScheduleMessage>
#include <KIdentityManagementCore/Identity>
#include <KJob>
#include <KMime/Message>

class InvitationResponseJob : public KJob
{
    Q_OBJECT

public:
    InvitationResponseJob(const KCalendarCore::ScheduleMessage::Ptr &schedule,
                          const KCalendarCore::Event::Ptr &reply,
                          const QString &receiver,
                          bool accept,
                          QObject *parent = nullptr);
    void start() override;

private:
    void queueReply();
    void fail(const QString &message);

    KCalendarCore::ScheduleMessage::Ptr m_schedule;
    KCalendarCore::Event::Ptr m_reply;
    QString m_receiver;
    bool m_accept;
    KIdentityManagementCore::Identity m_identity;
    int m_transportId = -1;
};
