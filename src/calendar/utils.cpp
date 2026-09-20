// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "utils.h"
#include <KLocalizedString>
#include <QDate>
#include <QLocale>
#include <QRegularExpression>
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

CalendarUtils::CalendarUtils(QObject *parent)
    : QObject(parent)
{
    QTime time;
    for (int i = 1; i < 24; i++) {
        time.setHMS(i, 0, 0);
        m_hourlyViewLocalisedHourLabels.append(QLocale::system().toString(time, QLocale::NarrowFormat));
    }
}

QString CalendarUtils::secondsToReminderLabel(const qint64 seconds) const
{
    if (seconds < 0) {
        return i18n("%1 before start of event", numAndUnit(seconds * -1));
    } else if (seconds > 0) {
        return i18n("%1 after start of event", numAndUnit(seconds));
    } else {
        return i18n("On event start");
    }
}

QString CalendarUtils::formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, const bool allDay)
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

Merkuro::KDateTime CalendarUtils::parseDateString(const QString &dateString) const
{
    const auto locale = QLocale();
    const auto defaultParse = [&]() {
        return Merkuro::KDateTime(QDateTime(locale.toDate(dateString, QLocale::NarrowFormat), QTime(0, 0)));
    };

    const auto delimiterMatch = QRegularExpression(QStringLiteral("\\D")).match(dateString);
    if (!delimiterMatch.hasMatch()) {
        return defaultParse();
    }

    const auto delimiter = delimiterMatch.captured(0);
    const auto formatParts = locale.dateFormat(QLocale::NarrowFormat).split(delimiter);
    const auto formatPartIndex = [&formatParts](const QChar marker) {
        for (qsizetype i = 0; i < formatParts.size(); ++i) {
            if (formatParts.at(i).contains(marker, Qt::CaseInsensitive)) {
                return i;
            }
        }
        return qsizetype{-1};
    };
    const auto dayPosition = formatPartIndex(u'd');
    const auto monthPosition = formatPartIndex(u'm');
    const auto yearPosition = formatPartIndex(u'y');
    const auto parts = dateString.split(delimiter);
    if (parts.size() != 3 || dayPosition < 0 || monthPosition < 0 || yearPosition < 0) {
        return defaultParse();
    }

    const auto yearPart = parts.at(yearPosition).trimmed();
    const auto currentYear = QString::number(QDate::currentDate().year());
    if (yearPart.isEmpty() || yearPart.size() >= currentYear.size()) {
        return defaultParse();
    }

    const QString year = currentYear.left(currentYear.size() - yearPart.size()) + yearPart;
    bool ok = false;
    const auto day = parts.at(dayPosition).toInt(&ok);
    if (!ok) {
        return Merkuro::KDateTime();
    }
    const auto month = parts.at(monthPosition).toInt(&ok);
    if (!ok) {
        return Merkuro::KDateTime();
    }
    const auto date = QDate(year.toInt(&ok), month, day);
    return ok && date.isValid() ? Merkuro::KDateTime(QDateTime(date, QTime(0, 0))) : Merkuro::KDateTime();
}

int CalendarUtils::fullDaysBetweenDates(const Merkuro::KDateTime &date1, const Merkuro::KDateTime &date2) const
{
    return date1.date().daysTo(date2.date()) + 1;
}

QDate CalendarUtils::startOfWeek(const QDate &date, const QLocale &locale)
{
    return date.addDays(-((date.dayOfWeek() - locale.firstDayOfWeek() + 7) % 7));
}

int CalendarUtils::weekNumber(const Merkuro::KDateTime &date) const
{
    return date.date().weekNumber();
}

QStringList CalendarUtils::hourlyViewLocalisedHourLabels() const
{
    return m_hourlyViewLocalisedHourLabels;
}

#include "moc_utils.cpp"
