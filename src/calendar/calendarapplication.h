// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once

#include "calendarconfig.h"
#include "hourlyincidencemodel.h"

#include <Akonadi/ETMCalendar>
#include <QActionGroup>
#include <QObject>
#include <QWindow>
#include <abstractmerkuroapplication.h>

#include <qqmlintegration.h>

class QQuickWindow;

class CalendarApplication : public AbstractMerkuroApplication
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar MEMBER m_calendar NOTIFY calendarChanged)

public:
    enum Mode {
        Month = 1,
        Week = 2,
        ThreeDay = 4,
        Day = 8,
        Schedule = 16,
        Todo = 32,
        WorkWeek = 64,
        Event = Month | Week | ThreeDay | Day | Schedule | WorkWeek,
    };
    Q_ENUM(Mode)

    explicit CalendarApplication(QObject *parent = nullptr);

    QList<KirigamiActionCollection *> actionCollections() const override;

    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    QWindow *window() const;
    void setWindow(QWindow *window);

    // D-Bus interface
    void showIncidenceByUid(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken);

Q_SIGNALS:
    void openMonthView();
    void openWeekView();
    void openWorkWeekView();
    void openThreeDayView();
    void openDayView();
    void openScheduleView();
    void openTodoView();
    void moveViewForwards();
    void moveViewBackwards();
    void moveViewToToday();
    void openDateChanger();
    void createNewEvent();
    void createNewTodo();
    void windowChanged();
    void importCalendar();
    void configureSchedule();
    void openLanguageSwitcher();
    void undo();
    void redo();
    void todoViewSortAlphabetically();
    void todoViewSortByDueDate();
    void todoViewSortByPriority();
    void todoViewOrderAscending();
    void todoViewOrderDescending();
    void todoViewShowCompleted();
    void todoViewShowCurrentDayOnly();
    void refreshAll();
    void openIncidence(const IncidenceData incidenceData, const QDateTime occurrence);
    void calendarChanged();
    void showMenubarChanged(bool state);

private Q_SLOTS:
    void handleMouseViewNavButtons(const Qt::MouseButton pressedButton);

private:
    void setupActions() override;
    bool showMenubar() const;

    KirigamiActionCollection *mSortCollection = nullptr;
    QWindow *m_window = nullptr;
    QActionGroup *const m_viewGroup;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    CalendarConfig *m_config = nullptr;
    Akonadi::ETMCalendar::Ptr m_calendar;
};
