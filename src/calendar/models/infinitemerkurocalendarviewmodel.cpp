// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "models/infinitemerkurocalendarviewmodel.h"
#include "incidenceoccurrencemodel.h"
#include "merkuro_calendar_debug.h"
#include <Akonadi/EntityTreeModel>
#include <QMetaEnum>
#include <cmath>

using namespace std::chrono_literals;

InfiniteMerkuroCalendarViewModel::InfiniteMerkuroCalendarViewModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void InfiniteMerkuroCalendarViewModel::setup()
{
    m_startDates.clear();
    m_firstDayOfMonthDates.clear();

    const auto today = QDate::currentDate();

    switch (m_scale) {
    case DayScale: {
        const auto firstDay = today.addDays(-m_datesToAdd / 2);
        addDayDates(true, firstDay);
        break;
    }
    case ThreeDayScale: {
        const auto firstDay = today.addDays((-m_datesToAdd * 3) / 2);
        addDayDates(true, firstDay, 3);
        break;
    }
    case WeekScale: {
        QDate firstDay = today.addDays(-today.dayOfWeek() + (m_locale.firstDayOfWeek() % 7));
        // We create dates before and after where our view will start from (which is today)
        firstDay = firstDay.addDays(-m_datesToAdd / 2 * 7);

        addWeekDates(true, firstDay);
        break;
    }
    case WorkWeekScale: {
        QDate firstDay = today.addDays(1 - today.dayOfWeek());
        firstDay = firstDay.addDays(-m_datesToAdd / 2 * 7);
        addWorkWeekDates(true, firstDay);
        break;
    }
    case MonthScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addMonths(-m_datesToAdd / 2);

        addMonthDates(true, firstDay);
        break;
    }
    case YearScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addYears(-m_datesToAdd / 2);

        addYearDates(true, firstDay);
        break;
    }
    case DecadeScale: {
        const int firstYear = ((today.year() / 10) * 10) - 1; // E.g. For 2020 have view start at 2019...
        QDate firstDay(firstYear, today.month(), 1);
        firstDay = firstDay.addYears(-m_datesToAdd / 2 * 10); // 3 * 4 grid so 12 years, end at 2030, and align for mid index to be current decade

        addDecadeDates(true, firstDay);
        break;
    }
    }
}

QVariant InfiniteMerkuroCalendarViewModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    if (m_scale == MonthScale && role != StartDateRole) {
        const QDate firstDay = m_firstDayOfMonthDates[idx.row()];

        switch (role) {
        case Qt::DisplayRole:
            return firstDay;
        case FirstDayOfMonthRole:
            return firstDay.startOfDay();
        case SelectedMonthRole:
            return firstDay.month();
        case SelectedYearRole:
            return firstDay.year();
        default:
            qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for first day:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
        }
    }

    const auto &startDate = m_startDates[idx.row()];

    switch (role) {
    case Qt::DisplayRole:
        return startDate;
    case StartDateRole:
        return startDate.startOfDay();
    case SelectedMonthRole:
        return startDate.month();
    case SelectedYearRole:
        return startDate.year();
    default:
        qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

int InfiniteMerkuroCalendarViewModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_startDates.length();
}

QHash<int, QByteArray> InfiniteMerkuroCalendarViewModel::roleNames() const
{
    return {
        {StartDateRole, QByteArrayLiteral("startDate")},
        {FirstDayOfMonthRole, QByteArrayLiteral("firstDayOfMonth")},
        {SelectedMonthRole, QByteArrayLiteral("selectedMonth")},
        {SelectedYearRole, QByteArrayLiteral("selectedYear")},
    };
}

int InfiniteMerkuroCalendarViewModel::moveToDate(const QDate &selectedDate, const QDate &currentDate, const int currentIndex)
{
    auto newIndex = 0;
    int role = Qt::DisplayRole;

    switch (m_scale) {
    case DecadeScale: {
        const auto decadeDiff = (selectedDate.year() / 10) - (currentDate.year() / 10);
        newIndex = currentIndex + decadeDiff;
        role = InfiniteMerkuroCalendarViewModel::StartDateRole;
        break;
    }
    case YearScale: {
        const auto yearDiff = selectedDate.year() - currentDate.year();
        newIndex = currentIndex + yearDiff;
        role = InfiniteMerkuroCalendarViewModel::StartDateRole;
        break;
    }
    case MonthScale: {
        const auto monthDiff = selectedDate.month() - currentDate.month() + (12 * (selectedDate.year() - currentDate.year()));
        newIndex = currentIndex + monthDiff;
        role = InfiniteMerkuroCalendarViewModel::FirstDayOfMonthRole;
        break;
    }
    // WorkWeekScale behaves like WeekScale for navigation
    case WorkWeekScale:
    case WeekScale: {
        const int daysTo = currentDate.daysTo(selectedDate) / 7;
        newIndex = currentIndex + daysTo;
        role = InfiniteMerkuroCalendarViewModel::StartDateRole;
        break;
    }
    case ThreeDayScale: {
        const int daysTo = currentDate.daysTo(selectedDate) / 3;
        newIndex = currentIndex + daysTo;
        role = InfiniteMerkuroCalendarViewModel::StartDateRole;
        break;
    }
    case DayScale: {
        const auto daysTo = currentDate.daysTo(selectedDate);
        newIndex = currentIndex + daysTo;
        role = InfiniteMerkuroCalendarViewModel::StartDateRole;
        break;
    }
    default:
        Q_UNREACHABLE();
    }

    auto firstItemDate = data(index(0, 0), role).toDateTime().date();
    auto lastItemDate = data(index(rowCount() - 1, 0), role).toDateTime().date();

    while (firstItemDate >= selectedDate) {
        addDates(false);
        firstItemDate = data(index(0, 0), role).toDateTime().date();
        newIndex = 0;
    }

    if (firstItemDate < selectedDate && newIndex == 0) {
        switch (m_scale) {
        case DecadeScale:
            newIndex += ((selectedDate.year() / 10) - (firstItemDate.year() / 10)) - 1;
            break;
        case YearScale:
            newIndex += selectedDate.year() - firstItemDate.year();
            break;
        case MonthScale:
            newIndex += selectedDate.month() - firstItemDate.month() + (12 * (selectedDate.year() - firstItemDate.year()));
            break;
        // WorkWeekScale behaves like WeekScale for navigation
        case WorkWeekScale:
        case WeekScale:
            newIndex += firstItemDate.daysTo(selectedDate) / 7;
            break;
        case ThreeDayScale:
            newIndex += firstItemDate.daysTo(selectedDate) / 3;
            break;
        case DayScale:
            newIndex += firstItemDate.daysTo(selectedDate);
            break;
        default:
            Q_UNREACHABLE();
        }
    }

    while (lastItemDate <= selectedDate) {
        addDates(true);
        lastItemDate = data(index(rowCount() - 1, 0), role).toDateTime().date();
    }

    if (m_scale == ThreeDayScale || m_scale == WeekScale || m_scale == WorkWeekScale) {
        const auto newIndexStartDate = index(newIndex, 0).data(StartDateRole).toDate();
        const auto startDateToSelectedDateDays = newIndexStartDate.daysTo(selectedDate);
        const auto dayDiffFloat = static_cast<float>(startDateToSelectedDateDays);

        if (m_scale == ThreeDayScale) {
            newIndex += floor(dayDiffFloat / 3);
        } else if (m_scale == WeekScale || m_scale == WorkWeekScale) {
            newIndex += floor(dayDiffFloat / 7);
        }
    }

    return newIndex;
}

void InfiniteMerkuroCalendarViewModel::addDates(const bool atEnd, const QDate startFrom)
{
    switch (m_scale) {
    case DayScale:
        addDayDates(atEnd, startFrom);
        break;
    case ThreeDayScale:
        addDayDates(atEnd, startFrom, 3);
        break;
    case WeekScale:
        addWeekDates(atEnd, startFrom);
        break;
    case WorkWeekScale:
        addWorkWeekDates(atEnd, startFrom);
        break;
    case MonthScale:
        addMonthDates(atEnd, startFrom);
        break;
    case YearScale:
        addYearDates(atEnd, startFrom);
        break;
    case DecadeScale:
        addDecadeDates(atEnd, startFrom);
        break;
    }
}

void InfiniteMerkuroCalendarViewModel::addDayDates(const bool atEnd, const QDate &startFrom, int amount)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate;
        if (startFrom.isValid() && i == 0) {
            startDate = startFrom;
        } else {
            if (atEnd) {
                startDate = m_startDates[rowCount() - 1].addDays(amount);
            } else {
                startDate = m_startDates[0].addDays(-amount);
            }
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteMerkuroCalendarViewModel::addWeekDates(const bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate;
        if (startFrom.isValid() && i == 0) {
            startDate = startFrom;
        } else {
            if (atEnd) {
                startDate = m_startDates[rowCount() - 1].addDays(7);
            } else {
                startDate = m_startDates[0].addDays(-7);
            }
        }

        if (startDate.dayOfWeek() != m_locale.firstDayOfWeek()) {
            startDate = startDate.addDays(-startDate.dayOfWeek() + (m_locale.firstDayOfWeek() % 7));
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteMerkuroCalendarViewModel::addWorkWeekDates(const bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate;
        if (startFrom.isValid() && i == 0) {
            startDate = startFrom;
        } else {
            if (atEnd) {
                startDate = m_startDates[rowCount() - 1].addDays(7);
            } else {
                startDate = m_startDates[0].addDays(-7);
            }
        }

        if (startDate.dayOfWeek() != Qt::Monday) {
            startDate = startDate.addDays(1 - startDate.dayOfWeek());
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteMerkuroCalendarViewModel::addMonthDates(const bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate firstDay;
        if (startFrom.isValid() && i == 0) {
            firstDay = startFrom;
        } else {
            if (atEnd) {
                firstDay = m_firstDayOfMonthDates[rowCount() - 1].addMonths(1);
            } else {
                firstDay = m_firstDayOfMonthDates[0].addMonths(-1);
            }
        }
        QDate startDate = firstDay;

        startDate = startDate.addDays(-startDate.dayOfWeek() + (m_locale.firstDayOfWeek() % 7));
        if (startDate >= firstDay) {
            startDate = startDate.addDays(-7);
        }

        if (atEnd) {
            m_firstDayOfMonthDates.append(firstDay);
            m_startDates.append(startDate);
        } else {
            m_firstDayOfMonthDates.insert(0, firstDay);
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteMerkuroCalendarViewModel::addYearDates(const bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate;
        if (startFrom.isValid() && i == 0) {
            startDate = startFrom;
        } else {
            if (atEnd) {
                startDate = m_startDates[rowCount() - 1].addYears(1);
            } else {
                startDate = m_startDates[0].addYears(-1);
            }
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteMerkuroCalendarViewModel::addDecadeDates(const bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate;
        if (startFrom.isValid() && i == 0) {
            startDate = startFrom;
        } else {
            if (atEnd) {
                startDate = m_startDates[rowCount() - 1].addYears(10);
            } else {
                startDate = m_startDates[0].addYears(-10);
            }
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

int InfiniteMerkuroCalendarViewModel::datesToAdd() const
{
    return m_datesToAdd;
}

void InfiniteMerkuroCalendarViewModel::setDatesToAdd(int datesToAdd)
{
    m_datesToAdd = datesToAdd;
    Q_EMIT datesToAddChanged();
}

int InfiniteMerkuroCalendarViewModel::scale() const
{
    return m_scale;
}

void InfiniteMerkuroCalendarViewModel::setScale(const int scale)
{
    if (m_scale == scale) {
        return;
    }

    beginResetModel();

    m_scale = scale;
    setup();
    Q_EMIT scaleChanged();

    endResetModel();
}

#include "moc_infinitemerkurocalendarviewmodel.cpp"
