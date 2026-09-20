// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QList>
#include <QObject>
#include <QString>
#include <merkurokdatetime.h>

namespace KCalendarCore
{
class Recurrence;
}

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
    Q_PROPERTY(Merkuro::KDateTime startDateTime MEMBER startDateTime)
    Q_PROPERTY(Merkuro::KDateTime endDateTime MEMBER endDateTime)
    Q_PROPERTY(bool allDay MEMBER allDay)
    Q_PROPERTY(ushort type MEMBER type)
    Q_PROPERTY(QList<int> monthDays MEMBER monthDays)
    Q_PROPERTY(QList<MonthPosition> monthPositions MEMBER monthPositions)
    Q_PROPERTY(QList<int> yearDays MEMBER yearDays)
    Q_PROPERTY(QList<int> yearDates MEMBER yearDates)
    Q_PROPERTY(QList<int> yearMonths MEMBER yearMonths)

public:
    RecurrenceData() = default;
    explicit RecurrenceData(const KCalendarCore::Recurrence *recurrence);

    Q_INVOKABLE QString recurrenceToString() const;
    Q_INVOKABLE QString recurrenceEndToString() const;

    QList<bool> weekdays;
    int duration;
    int frequency;
    Merkuro::KDateTime startDateTime;
    Merkuro::KDateTime endDateTime;
    bool allDay;
    ushort type;
    QList<int> monthDays;
    QList<MonthPosition> monthPositions;
    QList<int> yearDays;
    QList<int> yearDates;
    QList<int> yearMonths;
};
