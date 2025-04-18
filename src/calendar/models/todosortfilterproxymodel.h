// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/CalendarUtils>
#include <Akonadi/ETMCalendar>
#include <Akonadi/IncidenceTreeModel>
#include <Akonadi/TodoModel>
#include <KConfigWatcher>
#include <KFormat>
#include <KSharedConfig>
#include <QObject>
#include <QSortFilterProxyModel>
#include <QTimer>
#include <qqmlintegration.h>

class Filter;

class TodoSortFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Akonadi::IncidenceChanger *incidenceChanger READ incidenceChanger WRITE setIncidenceChanger NOTIFY incidenceChangerChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(Filter *filterObject READ filterObject WRITE setFilterObject NOTIFY filterObjectChanged)
    Q_PROPERTY(int showCompleted READ showCompleted WRITE setShowCompleted NOTIFY showCompletedChanged)
    Q_PROPERTY(int sortBy READ sortBy WRITE setSortBy NOTIFY sortByChanged)
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortAscendingChanged)
    Q_PROPERTY(bool showCompletedSubtodosInIncomplete READ showCompletedSubtodosInIncomplete WRITE setShowCompletedSubtodosInIncomplete NOTIFY
                   showCompletedSubtodosInIncompleteChanged)

public:
    enum Roles {
        StartTimeRole = Akonadi::TodoModel::CalendarRole + 1,
        EndTimeRole,
        DisplayDueDateRole,
        LocationRole,
        AllDayRole,
        CompletedRole,
        PriorityRole,
        ColorRole,
        CollectionIdRole,
        DurationStringRole,
        RecursRole,
        IsOverdueRole,
        IsReadOnly,
        IncidenceIdRole,
        IncidenceTypeRole,
        IncidenceTypeStrRole,
        IncidenceTypeIconRole,
        IncidencePtrRole,
        TagsRole,
        ItemRole,
        CategoriesRole,
        CategoriesDisplayRole,
        TreeDepthRole,
        TopMostParentSummaryRole, // These three here are used to help us conserve the proper sections
        TopMostParentDueDateRole, // in the Kirigami TreeListView, which otherwise will create new
        TopMostParentPriorityRole, // sections for subtasks
    };
    Q_ENUM(Roles)

    enum BaseTodoModelColumns {
        SummaryColumn = Akonadi::TodoModel::SummaryColumn,
        PriorityColumn = Akonadi::TodoModel::PriorityColumn,
        PercentColumn = Akonadi::TodoModel::PercentColumn,
        StartDateColumn = Akonadi::TodoModel::StartDateColumn,
        DueDateColumn = Akonadi::TodoModel::DueDateColumn,
        CategoriesColumn = Akonadi::TodoModel::CategoriesColumn,
        DescriptionColumn = Akonadi::TodoModel::DescriptionColumn,
        CalendarColumn = Akonadi::TodoModel::CalendarColumn,
    };
    Q_ENUM(BaseTodoModelColumns)

    enum ShowComplete {
        ShowAll = 0,
        ShowCompleteOnly,
        ShowIncompleteOnly,
    };
    Q_ENUM(ShowComplete)

    enum DueDateDisplayFormat {
        DisplayDateOnly,
        DisplayDateTimeAndIfOverdue,
    };
    Q_ENUM(DueDateDisplayFormat)

    explicit TodoSortFilterProxyModel(QObject *parent = nullptr);
    ~TodoSortFilterProxyModel() = default;

    int columnCount(const QModelIndex &parent) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override;

    bool filterAcceptsRowCheck(int row, const QModelIndex &sourceParent) const;
    bool hasAcceptedChildren(int row, const QModelIndex &sourceParent) const;

    Akonadi::ETMCalendar::Ptr calendar() const;
    Akonadi::IncidenceChanger *incidenceChanger() const;
    [[nodiscard]] int showCompleted() const;
    Filter *filterObject() const;
    [[nodiscard]] int sortBy() const;
    [[nodiscard]] bool sortAscending() const;
    [[nodiscard]] bool showCompletedSubtodosInIncomplete() const;

    void setCalendar(Akonadi::ETMCalendar::Ptr &calendar);
Q_SIGNALS:
    void calendarChanged();
    void filterObjectAboutToChange();
    void filterObjectChanged();
    void showCompletedChanged();
    void sortByChanged();
    void sortAscendingChanged();
    void showCompletedSubtodosInIncompleteChanged();
    void incidenceChangerChanged();

public Q_SLOTS:
    void setIncidenceChanger(Akonadi::IncidenceChanger *changer);
    void setFilterObject(Filter *filterObject);
    void setShowCompleted(const int showCompleted);
    void setSortBy(const int sortBy);
    void setSortAscending(const bool sortAscending);
    void setShowCompletedSubtodosInIncomplete(const bool showCompletedSubtodosInIncomplete);

    void sortTodoModel();
    void filterTodoName(const QString &name, const int showCompleted = ShowAll);

protected:
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    void setColorCache(const QHash<QString, QColor> colorCache);
    void emitDateDataChanged(const QModelIndex &idx);
    void updateDateLabels();
    void loadColors();
    [[nodiscard]] QHash<QString, QColor> colorCache() const;
    [[nodiscard]] QString todoDueDateDisplayString(const KCalendarCore::Todo::Ptr todo, const DueDateDisplayFormat format) const;

    [[nodiscard]] int compareStartDates(const QModelIndex &left, const QModelIndex &right) const;
    [[nodiscard]] int compareDueDates(const QModelIndex &left, const QModelIndex &right) const;
    [[nodiscard]] int compareCompletedDates(const QModelIndex &left, const QModelIndex &right) const;
    [[nodiscard]] int comparePriorities(const QModelIndex &left, const QModelIndex &right) const;
    [[nodiscard]] int compareCompletion(const QModelIndex &left, const QModelIndex &right) const;

    Akonadi::ETMCalendar::Ptr m_calendar;
    QScopedPointer<Akonadi::IncidenceTreeModel> m_todoTreeModel;
    QScopedPointer<Akonadi::TodoModel> m_baseTodoModel;
    Akonadi::IncidenceChanger *m_lastSetChanger = nullptr;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
    int m_showCompleted = ShowComplete::ShowAll;
    int m_showCompletedStore; // For when searches happen
    Filter *m_filterObject = nullptr;
    int m_sortColumn = DueDateColumn;
    bool m_sortAscending = false;
    bool m_showCompletedSubtodosInIncomplete = true;
    KFormat m_format;
    QTimer m_dateRefreshTimer;
    int m_dateRefreshTimerInterval = 60000; // msecs
    QDate m_lastDateRefreshDate = QDate::currentDate();
};
