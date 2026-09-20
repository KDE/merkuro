// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KCalendarCore/Duration>
#include <KFormat>
#include <QObject>
#include <merkurokdatetime.h>
#include <qqmlregistration.h>

class CalendarUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    QML_NAMED_ELEMENT(Utils)

    Q_PROPERTY(QStringList hourlyViewLocalisedHourLabels READ hourlyViewLocalisedHourLabels CONSTANT)

public:
    explicit CalendarUtils(QObject *parent = nullptr);

    [[nodiscard]] QStringList hourlyViewLocalisedHourLabels() const;

    Q_INVOKABLE Merkuro::KDateTime parseDateString(const QString &dateString) const;
    Q_INVOKABLE int fullDaysBetweenDates(const Merkuro::KDateTime &date1, const Merkuro::KDateTime &date2) const;

    /// Gives prettified time
    Q_INVOKABLE QString secondsToReminderLabel(const qint64 seconds) const;

    [[nodiscard]] static QString formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, const bool allDay);

    Q_INVOKABLE int weekNumber(const Merkuro::KDateTime &date) const;

    [[nodiscard]] static QDate startOfWeek(const QDate &date, const QLocale &locale);

private:
    QStringList m_hourlyViewLocalisedHourLabels;
};
