// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "datetimestate.h"
#include "utils.h"
#include <QTimer>

using namespace std::chrono_literals;

DateTimeState::DateTimeState(QObject *parent)
    : QObject(parent)
    , m_selectedDate(Merkuro::KDateTime(QDateTime::currentDateTime()))
    , m_currentDate(Merkuro::KDateTime(QDateTime::currentDateTime()))
{
    auto timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this, timer] {
        m_currentDate = Merkuro::KDateTime(QDateTime::currentDateTime());
        Q_EMIT currentDateChanged();

        // Repeat timer
        timer->start(60s);
    });
    timer->start(60s);
}

void DateTimeState::selectPreviousMonth()
{
    m_selectedDate = m_selectedDate.addMonths(-1);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::selectNextMonth()
{
    m_selectedDate = m_selectedDate.addMonths(1);
    Q_EMIT selectedDateChanged();
}

bool DateTimeState::isToday(const Merkuro::KDateTime &date) const
{
    return m_currentDate.sameDay(date);
}

void DateTimeState::addDays(const int days)
{
    m_selectedDate = m_selectedDate.addDays(days);
    Q_EMIT selectedDateChanged();
}

Merkuro::KDateTime DateTimeState::firstDayOfMonth() const
{
    auto date = m_selectedDate;
    date.setDate(QDate(m_selectedDate.year(), m_selectedDate.month(), 1));
    return date;
}

Merkuro::KDateTime DateTimeState::firstDayOfWeek() const
{
    auto result = m_selectedDate;
    result.setDate(CalendarUtils::startOfWeek(m_selectedDate.date(), m_locale));
    return result;
}

void DateTimeState::resetTime()
{
    m_selectedDate = Merkuro::KDateTime(QDateTime::currentDateTime());
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedDate(const Merkuro::KDateTime &date)
{
    m_selectedDate = date;
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedDay(const int day)
{
    m_selectedDate.setDay(day);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedMonth(const int month)
{
    m_selectedDate.setMonth(month);
    Q_EMIT selectedDateChanged();
}

void DateTimeState::setSelectedYear(const int year)
{
    m_selectedDate.setYear(year);
    Q_EMIT selectedDateChanged();
}

#include "moc_datetimestate.cpp"
