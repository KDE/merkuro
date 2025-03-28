// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp

import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.components

Kirigami.Page {
    id: root
    objectName: switch(daysToShow) {
        case 1:
            return "dayView";
        case 3:
            return "threeDayView";
        case 5:
            return "workWeekView";
        case 7:
        default:
            return "weekView";
    }

    property int daysToShow: 7
    property bool dragDropEnabled: true

    readonly property var openOccurrence: applicationWindow().openOccurrence
    readonly property var mode: switch(daysToShow) {
        case 1:
            return Calendar.CalendarApplication.Day;
        case 3:
            return Calendar.CalendarApplication.ThreeDay;
        case 5:
            return Calendar.CalendarApplication.WorkWeek;
        case 7:
        default:
            return Calendar.CalendarApplication.Week;
    }

    required property QQC2.Action createEventAction

    readonly property Kirigami.Action previousAction: Kirigami.Action {
        icon.name: "go-previous"
        text: switch (root.daysToShow) {
            case 1:
                return i18n("Previous Day")
            case 3:
                return i18n("Previous Three Days")
            case 5:
                return i18n("Previous Work Week")
            case 7:
                return i18n("Previous Week")
        }
        shortcut: StandardKey.MoveToPreviousPage
        onTriggered: Calendar.DateTimeState.addDays(-root.daysToShow)
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action nextAction: Kirigami.Action {
        icon.name: "go-next"
        text: switch (root.daysToShow) {
            case 1:
                return i18n("Next Day")
            case 3:
                return i18n("Next Three Days")
            case 5:
                return i18n("Next Work Week")
            case 7:
                return i18n("Next Week")
        }
        shortcut: StandardKey.MoveToNextPage
        onTriggered: Calendar.DateTimeState.addDays(root.daysToShow)
        displayHint: Kirigami.DisplayHint.IconOnly
    }
    readonly property Kirigami.Action todayAction: Kirigami.Action {
        icon.name: "go-jump-today"
        text: i18n("Now")
        shortcut: StandardKey.MoveToStartOfLine
        onTriggered: Calendar.DateTimeState.resetTime();
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    actions: [
        previousAction,
        nextAction,
        todayAction,
        createEventAction
    ]

    padding: 0

    titleDelegate: Calendar.ViewTitleDelegate {
        titleDateButton {
            range: true
            lastDate: Calendar.Utils.addDaysToDate(Calendar.DateTimeState.selectedDate, root.daysToShow - 1)
        }

        Repeater {
            id: weekViewScaleToggles

            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.fillWidth: true

            visible: !Kirigami.Settings.isMobile

            readonly property list<T.Action> actions: [
                Kirigami.Action {
                    fromQAction: Calendar.CalendarApplication.action("open_week_view")
                    text: i18nc("@action:inmenu open week view", "Week")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.Week
                    onTriggered: weekViewAction.trigger()
                    displayHint: Kirigami.DisplayHint.KeepVisible
                },
                Kirigami.Action {
                    fromQAction: Calendar.CalendarApplication.action("open_workweek_view")
                    text: i18nc("@action:inmenu open work week view", "Work Week")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.WorkWeek
                    onTriggered: workWeekViewAction.trigger()
                    displayHint: Kirigami.DisplayHint.KeepVisible
                },
                Kirigami.Action {
                    fromQAction: Calendar.CalendarApplication.action("open_threeday_view")
                    text: i18nc("@action:inmenu open 3 days view", "3 Days")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.ThreeDay
                    displayHint: Kirigami.DisplayHint.KeepVisible
                },
                Kirigami.Action {
                    fromQAction: Calendar.CalendarApplication.action("open_day_view")
                    text: i18nc("@action:inmenu open day view", "Day")
                    checkable: true
                    checked: pageStack.currentItem && pageStack.currentItem.mode === Calendar.CalendarApplication.Day
                    displayHint: Kirigami.DisplayHint.KeepVisible
                }
            ]

            model: actions

            delegate: QQC2.ToolButton {
                required property T.Action modelData
                action: modelData
            }
        }
    }

    Loader {
        id: swipeableViewLoader

        anchors.fill: parent
        active: Calendar.Config.hourlyViewMode === Calendar.Config.SwipeableInternalHourlyView

        sourceComponent: SwipeableInternalHourlyView {
            anchors.fill: parent

            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }

    Loader {
        id: basicViewLoader

        anchors.fill: parent
        active: Calendar.Config.hourlyViewMode === Calendar.Config.BasicInternalHourlyView

        sourceComponent: BasicInternalHourlyView {
            anchors.fill: parent

            startDate: root.daysToShow === 7 ? Calendar.DateTimeState.firstDayOfWeek
                       : root.daysToShow === 5 ? (Qt.locale().firstDayOfWeek === Qt.Monday ? Calendar.DateTimeState.firstDayOfWeek
                                                  : Calendar.Utils.addDaysToDate(Calendar.DateTimeState.firstDayOfWeek, 1))
                       : Calendar.DateTimeState.selectedDate
            daysToShow: root.daysToShow
            dragDropEnabled: root.dragDropEnabled
            openOccurrence: root.openOccurrence
        }
    }
}
