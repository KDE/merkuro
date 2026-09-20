// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "recurrencedata.h"

#include <KCalendarCore/Recurrence>
#include <KLocalizedString>
#include <QBitArray>
#include <QLocale>
#include <QStringList>

namespace
{

QString ordinalNumberToString(int number)
{
    const auto mod100 = number % 100;
    const auto suffix = mod100 > 10 && mod100 < 20 ? "th" : [&] {
        switch (number % 10) {
        case 1:
            return "st";
        case 2:
            return "nd";
        case 3:
            return "rd";
        default:
            return "th";
        }
    }();

    return i18n("%1%2", number, QString::fromLatin1(suffix));
}

}

RecurrenceData::RecurrenceData(const KCalendarCore::Recurrence *recurrence)
    : weekdays(7)
    , duration(recurrence->duration())
    , frequency(recurrence->frequency())
    , startDateTime(Merkuro::KDateTime(recurrence->startDateTime()))
    , endDateTime(Merkuro::KDateTime(recurrence->endDateTime()))
    , allDay(recurrence->allDay())
    , type(recurrence->recurrenceType())
    , monthDays(recurrence->monthDays())
    , yearDays(recurrence->yearDays())
    , yearDates(recurrence->yearDates())
    , yearMonths(recurrence->yearMonths())
{
    const auto weekDaysBits = recurrence->days();
    for (int i = 0; i < weekDaysBits.size(); ++i) {
        weekdays[i] = weekDaysBits[i];
    }

    const auto recurrenceMonthPositions = recurrence->monthPositions();
    for (const auto &position : recurrenceMonthPositions) {
        this->monthPositions.append({position.day(), position.pos()});
    }
}

QString RecurrenceData::recurrenceToString() const
{
    const auto locale = QLocale::system();

    switch (type) {
    case 0:
        return i18n("Never");
    case 1:
        return i18np("Every minute", "Every %1 minutes", frequency);
    case 2:
        return i18np("Every hour", "Every %1 hours", frequency);
    case 3:
        return i18np("Every day", "Every %1 days", frequency);
    case 4: {
        auto result = i18np("Every week", "Every %1 weeks", frequency);
        QStringList days;
        for (int i = 0; i < weekdays.size(); ++i) {
            if (weekdays[i]) {
                days.append(locale.dayName(i + 1, QLocale::LongFormat));
            }
        }
        if (!days.isEmpty()) {
            result = i18np("Every week on", "Every %1 weeks on", frequency) + u" " + days.join(u", ");
        }
        return result;
    }
    case 5: {
        QStringList positions;
        for (const auto &position : monthPositions) {
            positions.append(ordinalNumberToString(position.pos) + u" " + locale.dayName(position.day));
        }
        return i18np("Every month on the %2", "Every %1 months on the %2", frequency, positions.join(u", "));
    }
    case 6:
        return i18np("Every month on the %2", "Every %1 months on the %2", frequency, ordinalNumberToString(startDateTime.date().day()));
    case 7:
        return i18np("Every year on the %2 of %3",
                     "Every %1 years on the %2 of %3",
                     frequency,
                     ordinalNumberToString(startDateTime.date().day()),
                     locale.monthName(startDateTime.date().month()));
    case 8: {
        QStringList days;
        for (const auto day : yearDays) {
            days.append(ordinalNumberToString(day));
        }
        return i18np("Every year on the %2 day of the year", "Every %1 years on the %2 day of the year", frequency, days.join(u", "));
    }
    case 9: {
        QStringList positions;
        for (const auto &position : monthPositions) {
            positions.append(ordinalNumberToString(position.pos) + u" " + locale.dayName(position.day));
        }
        QStringList months;
        for (const auto month : yearMonths) {
            months.append(locale.monthName(month));
        }
        return i18np("Every year on the %2 of %3", "Every %1 years on the %2 of %3", frequency, positions.join(u", "), months.join(u", "));
    }
    case 10:
        return i18n("Complex recurrence rule");
    default:
        return i18n("Unknown");
    }
}

QString RecurrenceData::recurrenceEndToString() const
{
    switch (duration) {
    case -1:
        return i18n("Never ends");
    case 0:
        return endDateTime.isValid() ? i18n("Ends on %1", endDateTime.toLocaleDateString(QLocale::NarrowFormat)) : QString();
    default:
        return i18n("Ends after %1 occurrences", duration);
    }
}
