// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kdatetime.h"

#include <QLocale>
#include <QRegularExpression>

namespace Merkuro
{

KDateTime::KDateTime(const QDateTime &dateTime)
    : m_dateTime(dateTime)
{
}

QDateTime KDateTime::dateTime() const
{
    return m_dateTime;
}

void KDateTime::setDateTime(const QDateTime &dateTime)
{
    m_dateTime = dateTime;
}

QDate KDateTime::date() const
{
    return m_dateTime.date();
}

void KDateTime::setDate(const QDate &date)
{
    m_dateTime.setDate(date);
}

QTime KDateTime::time() const
{
    return m_dateTime.time();
}

void KDateTime::setTime(const QTime &time)
{
    m_dateTime.setTime(time);
}

int KDateTime::year() const
{
    return m_dateTime.date().year();
}

void KDateTime::setYear(int year)
{
    const auto date = m_dateTime.date();
    m_dateTime.setDate(QDate(year, date.month(), date.day()));
}

int KDateTime::month() const
{
    return m_dateTime.date().month();
}

void KDateTime::setMonth(int month)
{
    const auto date = m_dateTime.date();
    m_dateTime.setDate(QDate(date.year(), month, date.day()));
}

int KDateTime::day() const
{
    return m_dateTime.date().day();
}

void KDateTime::setDay(int day)
{
    const auto date = m_dateTime.date();
    m_dateTime.setDate(QDate(date.year(), date.month(), day));
}

int KDateTime::hour() const
{
    return m_dateTime.time().hour();
}

void KDateTime::setHour(int hour)
{
    const auto time = m_dateTime.time();
    m_dateTime.setTime(QTime(hour, time.minute(), time.second(), time.msec()));
}

int KDateTime::minute() const
{
    return m_dateTime.time().minute();
}

void KDateTime::setMinute(int minute)
{
    const auto time = m_dateTime.time();
    m_dateTime.setTime(QTime(time.hour(), minute, time.second(), time.msec()));
}

int KDateTime::second() const
{
    return m_dateTime.time().second();
}

void KDateTime::setSecond(int second)
{
    const auto time = m_dateTime.time();
    m_dateTime.setTime(QTime(time.hour(), time.minute(), second, time.msec()));
}

QTimeZone KDateTime::timeZone() const
{
    return m_dateTime.timeZone();
}

void KDateTime::setTimeZone(const QTimeZone &timeZone)
{
    m_dateTime.setTimeZone(timeZone);
}

bool KDateTime::isValid() const
{
    return m_dateTime.isValid();
}

bool KDateTime::isToday() const
{
    return m_dateTime.toLocalTime().date() == QDate::currentDate();
}

bool KDateTime::isCurrentMonth() const
{
    const auto date = m_dateTime.toLocalTime().date();
    const auto today = QDate::currentDate();
    return date.year() == today.year() && date.month() == today.month();
}

bool KDateTime::isCurrentYear() const
{
    return m_dateTime.toLocalTime().date().year() == QDate::currentDate().year();
}

QString KDateTime::toLocaleDateString(const QString &format) const
{
    return QLocale().toString(m_dateTime.toLocalTime(), format);
}

QString KDateTime::toLocaleDateString(QLocale::FormatType format) const
{
    return QLocale().toString(m_dateTime.toLocalTime(), format);
}

KDateTime KDateTime::addDays(int days) const
{
    return KDateTime(m_dateTime.addDays(days));
}

KDateTime KDateTime::addMonths(int months) const
{
    return KDateTime(m_dateTime.addMonths(months));
}

KDateTime KDateTime::addYears(int years) const
{
    return KDateTime(m_dateTime.addYears(years));
}

KDateTime KDateTime::addSecs(qint64 secs) const
{
    return KDateTime(m_dateTime.addSecs(secs));
}

KDateTime KDateTime::startOfDay() const
{
    return KDateTime(m_dateTime.date().startOfDay(m_dateTime.timeZone()));
}

KDateTime KDateTime::startOfMonth() const
{
    const QDate date = m_dateTime.date();
    return KDateTime(QDate(date.year(), date.month(), 1).startOfDay(m_dateTime.timeZone()));
}

KDateTime KDateTime::endOfMonth() const
{
    const QDate date = m_dateTime.date();
    return KDateTime(QDate(date.year(), date.month(), date.daysInMonth()).startOfDay(m_dateTime.timeZone()));
}

KDateTime KDateTime::endOfYear() const
{
    return KDateTime(QDate(m_dateTime.date().year(), 12, 31).startOfDay(m_dateTime.timeZone()));
}

bool KDateTime::operator==(const QDateTime &right) const
{
    return m_dateTime == right;
}

bool KDateTime::operator==(const KDateTime &right) const
{
    return m_dateTime == right.m_dateTime;
}

bool KDateTime::operator<(const QDateTime &right) const
{
    return m_dateTime < right;
}

bool KDateTime::operator<(const KDateTime &right) const
{
    return m_dateTime < right.m_dateTime;
}

bool KDateTime::operator<=(const QDateTime &right) const
{
    return m_dateTime <= right;
}

bool KDateTime::operator<=(const KDateTime &right) const
{
    return m_dateTime <= right.m_dateTime;
}

bool KDateTime::operator>(const QDateTime &right) const
{
    return m_dateTime > right;
}

bool KDateTime::operator>(const KDateTime &right) const
{
    return m_dateTime > right.m_dateTime;
}

bool KDateTime::operator>=(const QDateTime &right) const
{
    return m_dateTime >= right;
}

bool KDateTime::operator>=(const KDateTime &right) const
{
    return m_dateTime >= right.m_dateTime;
}

}
