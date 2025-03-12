// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KCalendarCore/Duration>
#include <KFormat>
#include <QObject>
#include <qqmlregistration.h>

class Utils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList hourlyViewLocalisedHourLabels READ hourlyViewLocalisedHourLabels CONSTANT)

public:
    explicit Utils(QObject *parent = nullptr);

    [[nodiscard]] QStringList hourlyViewLocalisedHourLabels() const;

    Q_INVOKABLE QDateTime addDaysToDate(const QDateTime &date, const int days);

    /// Gives prettified time
    Q_INVOKABLE QString secondsToReminderLabel(const qint64 seconds) const;

    [[nodiscard]] static QString formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, const bool allDay);

    Q_INVOKABLE int weekNumber(const QDate &date) const;

private:
    QStringList m_hourlyViewLocalisedHourLabels;
};
