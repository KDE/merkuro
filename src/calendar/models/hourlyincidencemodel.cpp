// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "hourlyincidencemodel.h"
#include <QSet>
#include <QTimeZone>
#include <algorithm>
#include <cmath>

using namespace std::chrono_literals;
using namespace Qt::Literals::StringLiterals;
HourlyIncidenceModel::HourlyIncidenceModel(QObject *parent)
    : QAbstractListModel(parent)
{
    mRefreshTimer.setSingleShot(true);
    mRefreshTimer.setInterval(200ms);
    mRefreshTimer.callOnTimeout(this, [this] {
        Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0), {IncidencesRole});
    });
}

int HourlyIncidenceModel::rowCount(const QModelIndex &parent) const
{
    // Number of weeks
    if (parent.isValid()) {
        return 0;
    }

    if (mSourceModel) {
        return qMax(mSourceModel->length(), 1);
    }
    return 0;
}

static double getDuration(const QDateTime &start, const QDateTime &end, int periodLength)
{
    return ((start.secsTo(end) * 1.0) / 60.0) / periodLength;
}

// We first sort all occurrences so we get all-day first (sorted by duration),
// and then the rest sorted by start-date.
QList<QModelIndex> HourlyIncidenceModel::sortedIncidencesFromSourceModel(const QDateTime &rowStart) const
{
    // Don't add days if we are going for a daily period
    const auto rowEnd = rowStart.date().endOfDay();
    QList<QModelIndex> sorted;
    sorted.reserve(mSourceModel->rowCount());
    // Get incidences from source model
    for (int row = 0; row < mSourceModel->rowCount(); row++) {
        const auto srcIdx = mSourceModel->index(row, 0, {});
        const auto start = srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone());
        const auto end = srcIdx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone());

        // Skip incidences not part of the week
        if (end < rowStart || start > rowEnd) {
            // qCWarning(MERKURO_CALENDAR_LOG) << "Skipping because not part of this week";
            continue;
        }

        if (m_filters.testFlag(NoAllDay) && srcIdx.data(IncidenceOccurrenceModel::AllDay).toBool()) {
            continue;
        }

        if (m_filters.testFlag(NoMultiDay) && srcIdx.data(IncidenceOccurrenceModel::Duration).value<KCalendarCore::Duration>().asDays() >= 1) {
            continue;
        }

        const auto incidencePtr = srcIdx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>();
        const auto incidenceIsTodo = incidencePtr->type() == Incidence::TypeTodo;
        if (!m_showTodos && incidenceIsTodo) {
            continue;
        }

        if (m_showTodos && incidenceIsTodo && !m_showSubTodos && !incidencePtr->relatedTo().isEmpty()) {
            continue;
        }
        // qCWarning(MERKURO_CALENDAR_LOG) << "found " << srcIdx.data(IncidenceOccurrenceModel::StartTime).toDateTime() <<
        // srcIdx.data(IncidenceOccurrenceModel::Summary).toString();
        sorted.append(srcIdx);
    }

    // Sort incidences by date
    std::sort(sorted.begin(), sorted.end(), [&](const QModelIndex &left, const QModelIndex &right) {
        // All-day first
        const auto leftAllDay = left.data(IncidenceOccurrenceModel::AllDay).toBool();
        const auto rightAllDay = right.data(IncidenceOccurrenceModel::AllDay).toBool();

        const auto leftDt = left.data(IncidenceOccurrenceModel::StartTime).toDateTime();
        const auto rightDt = right.data(IncidenceOccurrenceModel::StartTime).toDateTime();

        if (leftAllDay && !rightAllDay) {
            return true;
        }
        if (!leftAllDay && rightAllDay) {
            return false;
        }

        // The rest sorted by start date
        return leftDt < rightDt;
    });

    return sorted;
}

/*
 * Layout the lines:
 *
 * The line grouping algorithm then always picks the first incidence,
 * and tries to add more to the same line.
 *
 */
QList<IncidenceData> HourlyIncidenceModel::layoutLines(const QDateTime &rowStart) const
{
    QList<QModelIndex> sorted = sortedIncidencesFromSourceModel(rowStart);
    const auto rowEnd = rowStart.date().endOfDay();
    const int periodsPerDay = (24 * 60) / mPeriodLength;

    struct PositionData {
        QModelIndex idx;
        double start; // position in period units
        double duration; // width in period units
        int startMinute; // minutes from day start
        int endMinute; // minutes from day start
    };
    QList<PositionData> positioned;
    positioned.reserve(sorted.size());

    for (const auto &idx : sorted) {
        const auto startDT = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()) > rowStart
            ? idx.data(IncidenceOccurrenceModel::StartTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowStart;
        const auto endDT = idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()) < rowEnd
            ? idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone())
            : rowEnd;

        const auto start = ((startDT.time().hour() * 1.0) * (60.0 / mPeriodLength)) + ((startDT.time().minute() * 1.0) / mPeriodLength);
        auto duration =
            qMax(getDuration(startDT, idx.data(IncidenceOccurrenceModel::EndTime).toDateTime().toTimeZone(QTimeZone::systemTimeZone()), mPeriodLength), 1.0);

        if (start + duration > periodsPerDay) {
            duration = periodsPerDay - start;
        }

        const auto realEndMinutesFromDayStart = qMin((endDT.time().hour() * 60) + endDT.time().minute(), 24 * 60 * 60);
        const auto startMinutesFromDayStart =
            startDT.isValid() ? (startDT.time().hour() * 60) + startDT.time().minute() : qMax(realEndMinutesFromDayStart - mPeriodLength, 0);
        const auto endMinutesFromDayStart = static_cast<int>(floor(startMinutesFromDayStart + (mPeriodLength * duration)));

        positioned.append({idx, start, duration, startMinutesFromDayStart, endMinutesFromDayStart});
    }

    // Sweep-line column assignment: assign each incidence the lowest available column
    // so that overlapping incidences get consecutive columns (0, 1, 2, ...).
    struct ColumnEnd {
        int minute;
        int column;
    };

    // Active columns sorted by end minute for efficient reuse
    QList<ColumnEnd> activeColumns;
    QVector<int> incidenceColumn(positioned.size());

    // Process incidences in start-time order (already sorted)
    for (int i = 0; i < positioned.size(); i++) {
        const auto &pos = positioned[i];

        // Remove columns that are free before this incidence starts
        for (auto it = activeColumns.begin(); it != activeColumns.end();) {
            if (it->minute <= pos.startMinute) {
                it = activeColumns.erase(it);
            } else {
                ++it;
            }
        }

        // Find the lowest column number not currently in use
        QSet<int> usedColumns;
        for (const auto &ac : activeColumns) {
            usedColumns.insert(ac.column);
        }
        int col = 0;
        while (usedColumns.contains(col)) {
            col++;
        }

        incidenceColumn[i] = col;
        activeColumns.append({pos.endMinute, col});
    }

    // Compute per-incidence maxConcurrent: the number of columns used by all
    // incidences that overlap with it. This equals the max column index of any
    // overlapping incidence + 1.
    QVector<int> maxConcurrent(positioned.size(), 1);
    {
        // Build start/end events for sweep
        struct Event {
            int minute;
            int type; // +1 start, -1 end
            int index;
        };
        QList<Event> events;
        events.reserve(positioned.size() * 2);
        for (int i = 0; i < positioned.size(); i++) {
            events.append({positioned[i].startMinute, +1, i});
            events.append({positioned[i].endMinute, -1, i});
        }
        std::sort(events.begin(), events.end(), [](const Event &a, const Event &b) {
            if (a.minute != b.minute)
                return a.minute < b.minute;
            return a.type < b.type; // ends (-1) before starts (+1) at same minute
        });

        // Sweep: track active incidences, update maxConcurrent when a new incidence starts
        QSet<int> active;
        for (const auto &event : events) {
            if (event.type == +1) {
                active.insert(event.index);
                int maxCol = 0;
                for (int idx : active) {
                    maxCol = qMax(maxCol, incidenceColumn[idx]);
                }
                for (int idx : active) {
                    maxConcurrent[idx] = qMax(maxConcurrent[idx], maxCol + 1);
                }
            } else {
                active.remove(event.index);
            }
        }
    }

    // Build final IncidenceData with layout fields
    QList<IncidenceData> result;
    result.reserve(positioned.size());

    for (int i = 0; i < positioned.size(); i++) {
        const auto &pos = positioned[i];
        const auto idx = pos.idx;
        const int col = incidenceColumn[i];
        const int concurrent = maxConcurrent[i];
        const double widthShare = 1.0 / concurrent;
        const double priorTakenWidthShare = col * widthShare;

        IncidenceData incidenceData;
        incidenceData.text = idx.data(IncidenceOccurrenceModel::Summary).toString();
        incidenceData.description = idx.data(IncidenceOccurrenceModel::Description).toString();
        incidenceData.location = idx.data(IncidenceOccurrenceModel::Location).toString();
        incidenceData.startTime = idx.data(IncidenceOccurrenceModel::StartTime).toDateTime();
        incidenceData.endTime = idx.data(IncidenceOccurrenceModel::EndTime).toDateTime();
        incidenceData.allDay = idx.data(IncidenceOccurrenceModel::AllDay).toBool();
        incidenceData.todoCompleted = idx.data(IncidenceOccurrenceModel::TodoCompleted).toBool();
        incidenceData.priority = idx.data(IncidenceOccurrenceModel::Priority).toInt();
        incidenceData.starts = pos.start;
        incidenceData.duration = pos.duration;
        incidenceData.durationString = idx.data(IncidenceOccurrenceModel::DurationString).toString();
        incidenceData.recurs = idx.data(IncidenceOccurrenceModel::Recurs).toBool();
        incidenceData.hasReminders = idx.data(IncidenceOccurrenceModel::HasReminders).toBool();
        incidenceData.isOverdue = idx.data(IncidenceOccurrenceModel::IsOverdue).toBool();
        incidenceData.isReadOnly = idx.data(IncidenceOccurrenceModel::IsReadOnly).toBool();
        incidenceData.color = idx.data(IncidenceOccurrenceModel::Color).value<QColor>();
        incidenceData.collectionId = idx.data(IncidenceOccurrenceModel::CollectionId).value<qint64>();
        incidenceData.incidenceId = idx.data(IncidenceOccurrenceModel::IncidenceId).toString();
        incidenceData.incidenceType = idx.data(IncidenceOccurrenceModel::IncidenceType).value<KCalendarCore::IncidenceBase::IncidenceType>();
        incidenceData.incidenceTypeStr = idx.data(IncidenceOccurrenceModel::IncidenceTypeStr).toString();
        incidenceData.incidenceTypeIcon = idx.data(IncidenceOccurrenceModel::IncidenceTypeIcon).toString();
        incidenceData.incidencePtr = idx.data(IncidenceOccurrenceModel::IncidencePtr).value<KCalendarCore::Incidence::Ptr>();
        incidenceData.incidenceOccurrence = idx.data(IncidenceOccurrenceModel::IncidenceOccurrence);
        incidenceData.resizeable = idx.data(IncidenceOccurrenceModel::Resizeable).toBool();
        incidenceData.maxConcurrentIncidences = concurrent;
        incidenceData.widthShare = widthShare;
        incidenceData.priorTakenWidthShare = priorTakenWidthShare;

        result.append(incidenceData);
    }

    return result;
}

QVariant HourlyIncidenceModel::data(const QModelIndex &idx, int role) const
{
    Q_ASSERT(hasIndex(idx.row(), idx.column()) && mSourceModel);

    const auto rowStart = mSourceModel->start().addDays(idx.row()).startOfDay();
    switch (role) {
    case PeriodStartDateTimeRole:
        return rowStart;
    case IncidencesRole:
        return QVariant::fromValue(layoutLines(rowStart));
    default:
        return {};
    }
}

IncidenceOccurrenceModel *HourlyIncidenceModel::model() const
{
    return mSourceModel;
}

void HourlyIncidenceModel::setModel(IncidenceOccurrenceModel *model)
{
    beginResetModel();
    mSourceModel = model;
    Q_EMIT modelChanged();
    endResetModel();

    connect(model, &QAbstractItemModel::dataChanged, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &QAbstractItemModel::layoutChanged, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &QAbstractItemModel::modelReset, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &QAbstractItemModel::rowsInserted, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &QAbstractItemModel::rowsMoved, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &QAbstractItemModel::rowsRemoved, this, &HourlyIncidenceModel::scheduleReset);
    connect(model, &IncidenceOccurrenceModel::lengthChanged, this, [this] {
        beginResetModel();
        endResetModel();
    });
}

void HourlyIncidenceModel::scheduleReset()
{
    if (!mRefreshTimer.isActive()) {
        mRefreshTimer.start();
    }
}

int HourlyIncidenceModel::periodLength() const
{
    return mPeriodLength;
}

void HourlyIncidenceModel::setPeriodLength(int periodLength)
{
    if (mPeriodLength == periodLength) {
        return;
    }
    mPeriodLength = periodLength;
    Q_EMIT periodLengthChanged();

    scheduleReset();
}

HourlyIncidenceModel::Filters HourlyIncidenceModel::filters() const
{
    return m_filters;
}

void HourlyIncidenceModel::setFilters(HourlyIncidenceModel::Filters filters)
{
    if (m_filters == filters) {
        return;
    }
    m_filters = filters;
    Q_EMIT filtersChanged();

    scheduleReset();
}

bool HourlyIncidenceModel::showTodos() const
{
    return m_showTodos;
}

void HourlyIncidenceModel::setShowTodos(const bool showTodos)
{
    if (showTodos == m_showTodos) {
        return;
    }

    m_showTodos = showTodos;
    Q_EMIT showTodosChanged();

    scheduleReset();
}

bool HourlyIncidenceModel::showSubTodos() const
{
    return m_showSubTodos;
}

void HourlyIncidenceModel::setShowSubTodos(const bool showSubTodos)
{
    if (showSubTodos == m_showSubTodos) {
        return;
    }

    m_showSubTodos = showSubTodos;
    Q_EMIT showSubTodosChanged();

    scheduleReset();
}

bool HourlyIncidenceModel::active() const
{
    return m_active;
}

void HourlyIncidenceModel::setActive(const bool active)
{
    if (active == m_active) {
        return;
    }

    m_active = active;
    Q_EMIT activeChanged();

    if (active && mRefreshTimer.isActive() && std::chrono::milliseconds(mRefreshTimer.remainingTime()) > 200ms) {
        Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0));
        mRefreshTimer.stop();
    }
    mRefreshTimer.setInterval(active ? 200ms : 1000ms);
}

QHash<int, QByteArray> HourlyIncidenceModel::roleNames() const
{
    return {
        {IncidencesRole, "incidences"_ba},
        {PeriodStartDateTimeRole, "periodStartDateTime"_ba},
    };
}

#include "moc_hourlyincidencemodel.cpp"
