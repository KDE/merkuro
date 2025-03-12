// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

Column {
    id: root

    readonly property bool isDark: Calendar.CalendarUiUtils.darkMode

    required property date startDate

    required property bool isCurrentView
    required property bool showDayIndicator
    required property bool dragDropEnabled

    required property int month
    required property int daysToShow
    required property real dayWidth
    required property real dayHeight
    required property int listViewSpacing

    required property var openOccurrence

    property int numberOfLinesShown: 0

    // Weeks
    Repeater {
        model: Calendar.MultiDayIncidenceModel {
            periodLength: 7
            showTodos: Calendar.Config.showTodosInCalendarViews
            showSubTodos: Calendar.Config.showSubtodosInCalendarViews
            active: root.isCurrentView
            model: Calendar.IncidenceOccurrenceModel {
                start: root.startDate
                length: root.daysToShow
                calendar: Calendar.CalendarManager.calendar
                filter: Calendar.Filter
            }
        }

        // One row => one week
        Item {
            id: weekDelegate

            required property int index
            required property var incidences
            required property var periodStartDate

            width: parent.width
            height: root.dayHeight
            clip: true

            ListView {
                id: linesRepeater

                anchors {
                    fill: parent
                    // Offset for date
                    topMargin: root.showDayIndicator ? Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 : 0
                    rightMargin: spacing
                }

                // DO NOT use a ScrollView as a bug causes this to crash randomly.
                // So we instead make the ListView act like a ScrollView on desktop. No crashing now!
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Kirigami.Settings.isMobile ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

                clip: true
                spacing: root.listViewSpacing

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                onCountChanged: root.numberOfLinesShown = count

                model: weekDelegate.incidences
                delegate: Item {
                    id: line

                    required property var modelData

                    height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                    width: ListView.view.width

                    // Incidences
                    Repeater {
                        id: incidencesRepeater

                        model: line.modelData
                        delegate: Calendar.DayGridViewIncidenceDelegate {
                            id: incidenceDelegate

                            required property var modelData

                            starts: incidenceDelegate.modelData.starts
                            duration: incidenceDelegate.modelData.duration
                            month: root.month
                            incidenceId: incidenceDelegate.modelData.incidenceId
                            occurrenceDate: incidenceDelegate.modelData.startTime
                            occurrenceEndDate: incidenceDelegate.modelData.endTime
                            incidencePtr: incidenceDelegate.modelData.incidencePtr
                            allDay: incidenceDelegate.modelData.allDay
                            isDark: root.isDark

                            dayWidth: root.dayWidth
                            height: line.height
                            parentViewSpacing: root.spacing
                            horizontalSpacing: linesRepeater.spacing
                            openOccurrenceId: root.openOccurrence ? root.openOccurrence.incidenceId : ""
                            dragDropEnabled: root.dragDropEnabled
                        }
                    }
                }

                Calendar.DayTapHandler {
                    id: listViewMenu
                    addDate: {
                        const baseDate = weekDelegate.periodStartDate
                        const rowDayIndex = Math.floor(clickX / root.dayWidth)
                        return new Date(baseDate.setDate(baseDate.getDate() + rowDayIndex))
                    }
                    onDeselect: Calendar.CalendarUiUtils.appMain.incidenceInfoViewer.close()
                }
            }
        }
    }
}
