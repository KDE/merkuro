// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include <QAbstractItemModel>
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>

namespace KCalendarCore
{
class Incidence;
}

/**
 * Each toplevel index represents a day.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class HourlyIncidenceModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(HourlyIncidenceModel::Filters filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(IncidenceOccurrenceModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(bool showTodos READ showTodos WRITE setShowTodos NOTIFY showTodosChanged)
    Q_PROPERTY(bool showSubTodos READ showSubTodos WRITE setShowSubTodos NOTIFY showSubTodosChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)

public:
    enum Filter {
        NoAllDay = 0x1,
        NoMultiDay = 0x2,
    };
    Q_DECLARE_FLAGS(Filters, Filter)
    Q_FLAGS(Filters)
    Q_ENUM(Filter)

    enum Roles {
        IncidencesRole = IncidenceOccurrenceModel::LastRole,
        PeriodStartDateTimeRole,
    };

    explicit HourlyIncidenceModel(QObject *parent = nullptr);
    ~HourlyIncidenceModel() override = default;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    IncidenceOccurrenceModel *model() const;
    [[nodiscard]] int periodLength() const;
    [[nodiscard]] HourlyIncidenceModel::Filters filters() const;
    [[nodiscard]] bool showTodos() const;
    [[nodiscard]] bool showSubTodos() const;
    [[nodiscard]] bool active() const;
    void setActive(const bool active);

Q_SIGNALS:
    void periodLengthChanged();
    void filtersChanged();
    void modelChanged();
    void showTodosChanged();
    void showSubTodosChanged();
    void activeChanged();

public Q_SLOTS:
    void setModel(IncidenceOccurrenceModel *model);
    void setPeriodLength(int periodLength);
    void setFilters(HourlyIncidenceModel::Filters filters);
    void setShowTodos(const bool showTodos);
    void setShowSubTodos(const bool showSubTodos);

private Q_SLOTS:
    void scheduleReset();

private:
    [[nodiscard]] QList<QModelIndex> sortedIncidencesFromSourceModel(const QDateTime &rowStart) const;
    [[nodiscard]] QVariantList layoutLines(const QDateTime &rowStart) const;

    QTimer mRefreshTimer;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    QList<QVariantList> m_laidOutLines;
    int mPeriodLength{15}; // In minutes
    HourlyIncidenceModel::Filters m_filters;
    bool m_showTodos = true;
    bool m_showSubTodos = true;
    bool m_active = true;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(HourlyIncidenceModel::Filters)
