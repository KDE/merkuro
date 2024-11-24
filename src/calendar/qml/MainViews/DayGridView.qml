// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.utils
import "dateutils.js" as DateUtils

Item {
    id: root

    property var openOccurrence

    property int daysToShow: daysPerRow * 6
    property int daysPerRow: 7
    property real weekHeaderWidth: Calendar.Config.showWeekNumbers ? Kirigami.Units.gridUnit * 1.5 : 0

    readonly property date currentDate: Calendar.DateTimeState.currentDate
    // Getting the components once makes this faster when we need them repeatedly
    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear:currentDate.getFullYear()

    property date firstDayOfMonth: DateUtils.getFirstDayOfMonth(currentDate)
    property date startDate: DateUtils.getFirstDayOfWeek(firstDayOfMonth)
    readonly property int month: firstDayOfMonth.getMonth()

    property bool paintGrid: true
    property bool showDayIndicator: true
    property Component dayHeaderDelegate
    property Component weekHeaderDelegate
    property alias bgLoader: backgroundLoader.item
    property bool isCurrentView: true
    property bool dragDropEnabled: true

    readonly property alias foregroundLoader: foregroundLoader

    //Internal
    property int numberOfRows: (daysToShow / daysPerRow)
    property real dayWidth: Calendar.Config.showWeekNumbers ?
        ((width - weekHeaderWidth) / daysPerRow) - spacing : // No spacing on right, spacing in between weekheader and monthgrid
        (width - weekHeaderWidth - (spacing * (daysPerRow - 1))) / daysPerRow // No spacing on left or right of month grid when no week header
    property real dayHeight: ((height - bgLoader.dayLabelsBar.height) / numberOfRows) - spacing
    property int spacing: Calendar.Config.monthGridBorderWidth // Between grid squares in background
    property int listViewSpacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ?
        Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing // Between lines of incidences ( ====== <- )
    readonly property int mode: Calendar.CalendarApplication.Event

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : (foregroundLoader.item.numberOfLinesShown ?? 0) * Kirigami.Units.gridUnit) + bgLoader.dayLabelsBar.height
    height: implicitHeight

    Kirigami.Separator {
        id: gridBackground
        anchors {
            fill: parent
            topMargin: root.bgLoader.dayLabelsBar.height
        }
        visible: backgroundLoader.status === Loader.Ready
    }

    // Background
    Loader {
        id: backgroundLoader
        anchors.fill: parent
        asynchronous: !root.isCurrentView
        sourceComponent: DayGridViewBackground {
            id: rootBackgroundColumn
            parentGridView: root
            weekHeaderDelegate: root.weekHeaderDelegate
            dayHeaderDelegate: root.dayHeaderDelegate
            startDate: root.startDate
            month: root.month
            dayWidth: root.dayWidth
            dayHeight: root.dayHeight
            daysPerRow: root.daysPerRow
            daysToShow: root.daysToShow
            numberOfRows: root.numberOfRows
            spacing: root.spacing
            listViewSpacing: root.listViewSpacing
            isCurrentView: root.isCurrentView
            showDayIndicator: root.showDayIndicator
        }
    }

    Loader {
        id: foregroundLoader
        anchors.fill: parent
        asynchronous: !root.isCurrentView

        sourceComponent: DayGridViewForeground {
            id: rootForegroundColumn
            startDate: root.startDate
            month: root.month
            dayWidth: root.dayWidth
            dayHeight: root.dayHeight
            daysToShow: root.daysToShow
            spacing: root.spacing
            listViewSpacing: root.listViewSpacing
            isCurrentView: root.isCurrentView
            showDayIndicator: root.showDayIndicator
            openOccurrence: root.openOccurrence
            dragDropEnabled: root.dragDropEnabled

            anchors {
                fill: parent
                topMargin: root.bgLoader.dayLabelsBar.height + root.spacing
                leftMargin: Calendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
            }
        }
    }
}
