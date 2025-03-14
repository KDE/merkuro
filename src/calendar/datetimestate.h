// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QDateTime>
#include <QLocale>
#include <QObject>
#include <qdatetime.h>
#include <qqmlintegration.h>

class DateTimeState : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// This property holds the current selected date by the user
    Q_PROPERTY(QDateTime selectedDate MEMBER m_selectedDate NOTIFY selectedDateChanged)

    /// This property holds the first day of the month selected by the user
    Q_PROPERTY(QDateTime firstDayOfMonth READ firstDayOfMonth NOTIFY selectedDateChanged)

    /// This property holds the first day of the week selected by the user
    Q_PROPERTY(QDateTime firstDayOfWeek READ firstDayOfWeek NOTIFY selectedDateChanged)

    Q_PROPERTY(QDateTime currentDate MEMBER m_currentDate NOTIFY currentDateChanged)

public:
    explicit DateTimeState(QObject *parent = nullptr);

    [[nodiscard]] QDateTime firstDayOfMonth() const;
    [[nodiscard]] QDateTime firstDayOfWeek() const;

    Q_INVOKABLE void setSelectedYearMonthDay(const int year, const int month, const int day);
    Q_INVOKABLE void setSelectedDay(const int day);
    Q_INVOKABLE void setSelectedMonth(const int month);
    Q_INVOKABLE void setSelectedYear(const int year);

    Q_INVOKABLE void selectPreviousMonth();
    Q_INVOKABLE void selectNextMonth();

    Q_INVOKABLE void addDays(const int days);
    [[nodiscard]] Q_INVOKABLE bool isToday(const QDate &date) const;

    /// Reset to current time
    Q_INVOKABLE void resetTime();

Q_SIGNALS:
    void selectedDateChanged();
    void currentDateChanged();

private:
    QDateTime m_selectedDate;
    QDateTime m_currentDate;
    QLocale m_locale;
};
