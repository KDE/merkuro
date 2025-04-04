// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "hourlyincidencemodel.h"
#include "multidayincidencemodel.h"
#include <Akonadi/ETMCalendar>
#include <QLocale>
#include <qqmlintegration.h>

class InfiniteMerkuroCalendarViewModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    // Amount of dates to add each time the model adds more dates
    Q_PROPERTY(int datesToAdd READ datesToAdd WRITE setDatesToAdd NOTIFY datesToAddChanged)
    Q_PROPERTY(int scale READ scale WRITE setScale NOTIFY scaleChanged)

public:
    // The decade scale is designed to be used in a 4x3 grid, so shows 12 years at a time
    enum Scale {
        DayScale,
        ThreeDayScale,
        WeekScale,
        WorkWeekScale,
        MonthScale,
        YearScale,
        DecadeScale,
        InvalidScale,
    };
    Q_ENUM(Scale)

    enum Roles {
        StartDateRole = Qt::UserRole + 1,
        FirstDayOfMonthRole,
        SelectedMonthRole,
        SelectedYearRole,
    };
    Q_ENUM(Roles)

    explicit InfiniteMerkuroCalendarViewModel(QObject *parent = nullptr);
    ~InfiniteMerkuroCalendarViewModel() override = default;

    void setup();
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE int moveToDate(const QDate &selectedDate, const QDate &currentDate, const int currentIndex);
    Q_INVOKABLE void addDates(const bool atEnd, const QDate startFrom = QDate());
    void addDayDates(const bool atEnd, const QDate &startFrom, int amount = 1);
    void addWeekDates(const bool atEnd, const QDate &startFrom);
    void addWorkWeekDates(const bool atEnd, const QDate &startFrom);
    void addMonthDates(const bool atEnd, const QDate &startFrom);
    void addYearDates(const bool atEnd, const QDate &startFrom);
    void addDecadeDates(const bool atEnd, const QDate &startFrom);

    [[nodiscard]] int datesToAdd() const;
    void setDatesToAdd(const int datesToAdd);

    [[nodiscard]] int scale() const;
    void setScale(const int scale);

Q_SIGNALS:
    void datesToAddChanged();
    void scaleChanged();

private:
    QList<QDate> m_startDates;
    QList<QDate> m_firstDayOfMonthDates;
    QLocale m_locale;
    int m_datesToAdd = 10;
    int m_scale = InvalidScale;
};
