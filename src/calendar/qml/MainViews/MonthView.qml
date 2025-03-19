// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

Kirigami.Page {
    id: root

    required property QQC2.Action createEventAction

    property bool initialMonth: true
    property var openOccurrence: null

    readonly property int mode: Calendar.CalendarApplication.Month

    property bool dragDropEnabled: true

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: i18n("Previous Month")
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: Calendar.DateTimeState.selectPreviousMonth()
        displayHint: Kirigami.DisplayHint.IconOnly
    }

    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: i18n("Next Month")
        shortcut: StandardKey.MoveToNextPage
        onTriggered: Calendar.DateTimeState.selectNextMonth()
        displayHint: Kirigami.DisplayHint.IconOnly
    }

    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Today")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: Calendar.DateTimeState.resetTime();
    }

    actions: [
        previousAction,
        nextAction,
        todayAction,
        createEventAction
    ]

    padding: 0

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    titleDelegate: Calendar.ViewTitleDelegate {}

    Loader {
        id: swipeableViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthGridMode === Calendar.Config.SwipeableMonthGrid
        sourceComponent: SwipeableMonthGridView {
            anchors.fill: parent

            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }

    Loader {
        id: basicViewLoader
        anchors.fill: parent
        active: Calendar.Config.monthGridMode === Calendar.Config.BasicMonthGrid
        sourceComponent: DayGridView {
            anchors.fill: parent

            firstDayOfMonth: Calendar.DateTimeState.firstDayOfMonth
            startDate: Calendar.DateUtils.getFirstDayOfWeek(firstDayOfMonth)

            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }
}

