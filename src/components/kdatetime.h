// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <merkurocomponents_export.h>

#include <QDateTime>
#include <QDebug>
#include <QString>
#include <QTimeZone>
#include <qqmlregistration.h>

namespace Merkuro
{

/*!
 * \qmltype KDateTime
 * \inqmlmodule org.kde.merkuro.components
 *
 * \brief A timezone-aware date and time value that can be edited from QML.
 */
class MERKUROCOMPONENTS_EXPORT KDateTime
{
    Q_GADGET
    QML_VALUE_TYPE(KDateTime)

    /*!
     * \qmlproperty date KDateTime::dateTime
     * \brief The underlying date and time, including its timezone.
     */
    Q_PROPERTY(QDateTime dateTime READ dateTime WRITE setDateTime)

    /*!
     * \qmlproperty date KDateTime::date
     * \brief The date part of dateTime.
     */
    Q_PROPERTY(QDate date READ date WRITE setDate)

    /*!
     * \qmlproperty date KDateTime::time
     * \brief The time-of-day part of dateTime.
     */
    Q_PROPERTY(QTime time READ time WRITE setTime)

    /*!
     * \qmlproperty int KDateTime::year
     */
    Q_PROPERTY(int year READ year WRITE setYear)

    /*!
     * \qmlproperty int KDateTime::month
     * \brief The month, from 1 to 12.
     */
    Q_PROPERTY(int month READ month WRITE setMonth)

    /*!
     * \qmlproperty int KDateTime::day
     * \brief The day of the month, from 1 to 31.
     */
    Q_PROPERTY(int day READ day WRITE setDay)

    /*!
     * \qmlproperty int KDateTime::hour
     * \brief The hour, from 0 to 23.
     */
    Q_PROPERTY(int hour READ hour WRITE setHour)

    /*!
     * \qmlproperty int KDateTime::minute
     */
    Q_PROPERTY(int minute READ minute WRITE setMinute)

    /*!
     * \qmlproperty int KDateTime::second
     */
    Q_PROPERTY(int second READ second WRITE setSecond)

    /*!
     * \qmlproperty bool KDateTime::isValid
     */
    Q_PROPERTY(bool isValid READ isValid)

    /*!
     * \qmlproperty bool KDateTime::isToday
     * \brief Whether date is today, in the local timezone.
     */
    Q_PROPERTY(bool isToday READ isToday)

    /*!
     * \qmlproperty bool KDateTime::isCurrentMonth
     * \brief Whether date is in the current month and year, in the local timezone.
     */
    Q_PROPERTY(bool isCurrentMonth READ isCurrentMonth)

    /*!
     * \qmlproperty bool KDateTime::isCurrentYear
     * \brief Whether date is in the current year, in the local timezone.
     */
    Q_PROPERTY(bool isCurrentYear READ isCurrentYear)

    /*!
     * \qmlproperty var KDateTime::timeZone
     * \brief The timezone of dateTime.
     */
    Q_PROPERTY(QTimeZone timeZone READ timeZone WRITE setTimeZone)

public:
    explicit KDateTime(const QDateTime &dateTime = {});

    QDateTime dateTime() const;
    void setDateTime(const QDateTime &dateTime);

    QDate date() const;
    void setDate(const QDate &date);

    QTime time() const;
    void setTime(const QTime &time);

    int year() const;
    void setYear(int year);

    int month() const;
    void setMonth(int month);

    int day() const;
    void setDay(int day);

    int hour() const;
    void setHour(int hour);

    int minute() const;
    void setMinute(int minute);

    int second() const;
    void setSecond(int second);

    QTimeZone timeZone() const;
    void setTimeZone(const QTimeZone &timeZone);

    bool isValid() const;

    bool isToday() const;

    bool isCurrentMonth() const;

    bool isCurrentYear() const;

    /*!
     * \brief Returns date formatted according to format, in the local timezone.
     *
     * format uses the same pattern syntax as QLocale::toString(), for example
     * "d" for the day of month, "MMMM" for the full month name, or "yyyy" for
     * the year. Unlike JavaScript's \c toLocaleDateString(), this does not take
     * a separate locale argument; it always uses the default locale.
     */
    Q_INVOKABLE QString toLocaleDateString(const QString &format) const;

    /*!
     * \brief Returns date formatted using the locale's short format.
     */
    Q_INVOKABLE QString toLocaleDateString(QLocale::FormatType format) const;

    /*!
     * \brief Returns time formatted according to format, in the local timezone.
     */
    Q_INVOKABLE QString toLocaleTimeString(const QString &format) const;

    /*!
     * \brief Returns time formatted using the locale's short format.
     */
    Q_INVOKABLE QString toLocaleTimeString(QLocale::FormatType format) const;

    /*!
     * \brief Returns a copy of this date and time, days later (or earlier if negative).
     */
    Q_INVOKABLE KDateTime addDays(int days) const;

    /*!
     * \brief Returns a copy of this date and time, months later (or earlier if negative).
     */
    Q_INVOKABLE KDateTime addMonths(int months) const;

    /*!
     * \brief Returns a copy of this date and time, years later (or earlier if negative).
     */
    Q_INVOKABLE KDateTime addYears(int years) const;

    /*!
     * \brief Returns a copy of this date and time, seconds later (or earlier if negative).
     */
    Q_INVOKABLE KDateTime addSecs(qint64 secs) const;

    /*!
     * \brief Returns this date at midnight, keeping the same timezone.
     */
    Q_INVOKABLE KDateTime startOfDay() const;

    /*!
     * \brief Returns midnight on the first day of this date's month.
     */
    Q_INVOKABLE KDateTime startOfMonth() const;

    /*!
     * \brief Returns midnight on the last day of this date's month.
     */
    Q_INVOKABLE KDateTime endOfMonth() const;

    /*!
     * \brief Returns midnight on the last day of this date's year.
     */
    Q_INVOKABLE KDateTime endOfYear() const;

    bool operator==(const QDateTime &right) const;
    bool operator==(const KDateTime &right) const;

    bool operator<(const QDateTime &right) const;
    bool operator<(const KDateTime &right) const;

    bool operator<=(const QDateTime &right) const;
    bool operator<=(const KDateTime &right) const;

    bool operator>(const QDateTime &right) const;
    bool operator>(const KDateTime &right) const;

    bool operator>=(const QDateTime &right) const;
    bool operator>=(const KDateTime &right) const;

private:
    QDateTime m_dateTime;
};

MERKUROCOMPONENTS_EXPORT QDebug operator<<(QDebug debug, const KDateTime &dateTime);
}
