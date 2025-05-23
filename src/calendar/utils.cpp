// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "utils.h"
#include <KLocalizedString>
#include <QDate>
#include <QLocale>
#include <QtMath>
#include <chrono>

using namespace std::chrono_literals;

namespace
{
QString numAndUnit(const qint64 seconds)
{
    std::chrono::seconds secs{seconds};
    if (secs >= 24h * 2) {
        // 2 days +
        return i18nc("%1 is 2 or more", "%1 days", std::chrono::round<std::chrono::days>(secs).count());
    } else if (secs >= 24h) {
        return i18n("1 day");
    } else if (secs >= (2h)) {
        return i18nc("%1 is 2 or more", "%1 hours", std::chrono::round<std::chrono::hours>(secs).count()); // 2 hours +
    } else if (secs >= (1h)) {
        return i18n("1 hour");
    } else {
        return i18n("%1 minutes", std::chrono::round<std::chrono::minutes>(secs).count());
    }
};
}

Utils::Utils(QObject *parent)
    : QObject(parent)
{
    QTime time;
    for (int i = 1; i < 24; i++) {
        time.setHMS(i, 0, 0);
        m_hourlyViewLocalisedHourLabels.append(QLocale::system().toString(time, QLocale::NarrowFormat));
    }
}

QString Utils::secondsToReminderLabel(const qint64 seconds) const
{
    if (seconds < 0) {
        return i18n("%1 before start of event", numAndUnit(seconds * -1));
    } else if (seconds > 0) {
        return i18n("%1 after start of event", numAndUnit(seconds));
    } else {
        return i18n("On event start");
    }
}

QString Utils::formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, const bool allDay)
{
    if (duration.asSeconds() == 0) {
        return QString();
    } else {
        if (allDay) {
            return format.formatSpelloutDuration(duration.asSeconds() * 1000 + 24 * 60 * 60 * 1000);
        } else {
            return format.formatSpelloutDuration(duration.asSeconds() * 1000);
        }
    }
}

QDateTime Utils::addDaysToDate(const QDateTime &date, const int days)
{
    return date.addDays(days);
}

int Utils::weekNumber(const QDate &date) const
{
    return date.weekNumber();
}

QStringList Utils::hourlyViewLocalisedHourLabels() const
{
    return m_hourlyViewLocalisedHourLabels;
}

#include "moc_utils.cpp"
