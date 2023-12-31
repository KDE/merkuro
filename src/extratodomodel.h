// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <KConfigWatcher>
#include <KExtraColumnsProxyModel>
#include <KFormat>
#include <incidencetreemodel.h>
#include <todomodel.h>

class ExtraTodoModel : public KExtraColumnsProxyModel
{
    Q_OBJECT

public:
    enum Columns {
        StartTimeColumn = 0,
        EndTimeColumn,
        PriorityIntColumn,
    };
    Q_ENUM(Columns);

    enum Roles { // Remember to update roles in todosortfilterproxymodel
        StartTimeRole = TodoModel::CalendarRole + 1,
        EndTimeRole,
        LocationRole,
        AllDayRole,
        CompletedRole,
        PriorityRole,
        ColorRole,
        CollectionIdRole,
        DurationStringRole,
        RecursRole,
        IsOverdueRole,
        IncidenceIdRole,
        IncidenceTypeRole,
        IncidenceTypeStrRole,
        IncidenceTypeIconRole,
        IncidencePtrRole,
        TagsRole,
        ItemRole,
        CategoriesRole,
        CategoriesDisplayRole,
        TreeDepthRole
    };
    Q_ENUM(Roles);

    ExtraTodoModel(QObject *parent = nullptr);
    ~ExtraTodoModel() override = default;

    QVariant extraColumnData(const QModelIndex &parent, int row, int extraColumn, int role = Qt::DisplayRole) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Akonadi::ETMCalendar::Ptr calendar();
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);
    Akonadi::IncidenceChanger *incidenceChanger();
    void setIncidenceChanger(Akonadi::IncidenceChanger *changer);

    QHash<QString, QColor> colorCache();
    void setColorCache(QHash<QString, QColor> colorCache);
    void loadColors();

private:
    Akonadi::ETMCalendar::Ptr m_calendar;
    IncidenceTreeModel *m_todoTreeModel = nullptr;
    TodoModel *m_baseTodoModel = nullptr;
    Akonadi::IncidenceChanger *m_lastSetChanger = nullptr;
    QHash<QString, QColor> m_colors;
    KConfigWatcher::Ptr m_colorWatcher;
};
