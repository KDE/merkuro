// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "incidenceoccurrencemodel.h"
#include <QDateTime>
#include <QList>
#include <QSharedPointer>
#include <QTimer>
#include <qqmlintegration.h>

namespace KCalendarCore
{
class Incidence;
}

class IncidenceData
{
    Q_GADGET
    QML_VALUE_TYPE(incidenceData)

    Q_PROPERTY(QString text MEMBER text)
    Q_PROPERTY(QString description MEMBER description)
    Q_PROPERTY(QString location MEMBER location)
    Q_PROPERTY(QDateTime startTime MEMBER startTime)
    Q_PROPERTY(QDateTime endTime MEMBER endTime)
    Q_PROPERTY(bool allDay MEMBER allDay)
    Q_PROPERTY(bool todoCompleted MEMBER todoCompleted)
    Q_PROPERTY(int priority MEMBER priority)
    Q_PROPERTY(double starts MEMBER starts)
    Q_PROPERTY(double duration MEMBER duration)
    Q_PROPERTY(QString durationString MEMBER durationString)
    Q_PROPERTY(bool recurs MEMBER recurs)
    Q_PROPERTY(bool hasReminders MEMBER hasReminders)
    Q_PROPERTY(bool isOverdue MEMBER isOverdue)
    Q_PROPERTY(bool isReadOnly MEMBER isReadOnly)
    Q_PROPERTY(QColor color MEMBER color)
    Q_PROPERTY(Akonadi::Collection::Id collectionId MEMBER collectionId)
    Q_PROPERTY(QString incidenceId MEMBER incidenceId)
    Q_PROPERTY(KCalendarCore::IncidenceBase::IncidenceType incidenceType MEMBER incidenceType)
    Q_PROPERTY(QString incidenceTypeStr MEMBER incidenceTypeStr)
    Q_PROPERTY(QString incidenceTypeIcon MEMBER incidenceTypeIcon)
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr MEMBER incidencePtr)
    Q_PROPERTY(QVariant incidenceOccurrence MEMBER incidenceOccurrence)
    Q_PROPERTY(int maxConcurrentIncidences MEMBER maxConcurrentIncidences)
    Q_PROPERTY(double widthShare MEMBER widthShare)
    Q_PROPERTY(double priorTakenWidthShare MEMBER priorTakenWidthShare)

public:
    QString text;
    QString description;
    QString location;
    QDateTime startTime;
    QDateTime endTime;
    bool allDay;
    bool todoCompleted;
    int priority;
    double starts;
    double duration;
    QString durationString;
    bool recurs;
    bool hasReminders;
    bool isOverdue;
    bool isReadOnly;
    QColor color;
    Akonadi::Collection::Id collectionId;
    QString incidenceId;
    KCalendarCore::IncidenceBase::IncidenceType incidenceType;
    QString incidenceTypeStr;
    QString incidenceTypeIcon;
    KCalendarCore::Incidence::Ptr incidencePtr;
    QVariant incidenceOccurrence;
    int maxConcurrentIncidences;
    double widthShare;
    double priorTakenWidthShare;
};

/**
 * Each toplevel index represents a day.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class HourlyIncidenceModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

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
    Q_FLAG(Filters)

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
    [[nodiscard]] QList<IncidenceData> layoutLines(const QDateTime &rowStart) const;

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
