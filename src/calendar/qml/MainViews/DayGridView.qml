// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.utils
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Item {
    id: root

    property var openOccurrence

    property int daysToShow: daysPerRow * 6
    property int daysPerRow: 7
    property double weekHeaderWidth: Calendar.Config.showWeekNumbers ? Kirigami.Units.gridUnit * 1.5 : 0

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
    property int numberOfLinesShown: 0
    property int numberOfRows: (daysToShow / daysPerRow)
    property int dayWidth: Calendar.Config.showWeekNumbers ?
        ((width - weekHeaderWidth) / daysPerRow) - spacing : // No spacing on right, spacing in between weekheader and monthgrid
        (width - weekHeaderWidth - (spacing * (daysPerRow - 1))) / daysPerRow // No spacing on left or right of month grid when no week header
    property int dayHeight: ((height - bgLoader.dayLabelsBar.height) / numberOfRows) - spacing
    property int spacing: Calendar.Config.monthGridBorderWidth // Between grid squares in background
    property int listViewSpacing: root.dayWidth < (Kirigami.Units.gridUnit * 5 + Kirigami.Units.smallSpacing * 2) ?
        Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing // Between lines of incidences ( ====== <- )
    readonly property bool isDark: CalendarUiUtils.darkMode
    readonly property int mode: Calendar.CalendarApplication.Event

    implicitHeight: (numberOfRows > 1 ? Kirigami.Units.gridUnit * 10 * numberOfRows : numberOfLinesShown * Kirigami.Units.gridUnit) + bgLoader.dayLabelsBar.height
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
        sourceComponent: Column {
            id: rootBackgroundColumn

            property alias dayLabelsBar: dayLabelsBarComponent

            spacing: root.spacing
            anchors.fill: parent

            DayLabelsBar {
                id: dayLabelsBarComponent

                delegate: root.dayHeaderDelegate
                startDate: root.startDate
                dayWidth: root.dayWidth
                daysToShow: root.daysPerRow
                spacing: root.spacing

                anchors {
                    leftMargin: Calendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
                    left: parent.left
                    right: parent.right
                }
            }

            Repeater {
                model: root.numberOfRows

                // One row => one week
                Item {
                    id: weekRow

                    required property int index

                    width: parent.width
                    height: root.dayHeight
                    clip: true

                    RowLayout {
                        width: weekRow.width
                        height: weekRow.height
                        spacing: root.spacing

                        Loader {
                            id: weekHeader

                            property date startDate: Calendar.Utils.addDaysToDate(root.startDate, index * 7)

                            sourceComponent: root.weekHeaderDelegate
                            active: Calendar.Config.showWeekNumbers
                            visible: Calendar.Config.showWeekNumbers

                            Layout.preferredWidth: weekHeaderWidth
                            Layout.fillHeight: true
                        }

                        Item {
                            id: dayDelegate

                            property date startDate: Calendar.Utils.addDaysToDate(root.startDate, index * 7)

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Row {
                                id: grid

                                spacing: root.spacing
                                height: parent.height

                                Repeater {
                                    id: gridRepeater
                                    model: root.daysPerRow

                                    Item {
                                        id: gridItem

                                        required property var modelData

                                        readonly property date gridSquareDate: date
                                        readonly property date date: DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                        readonly property int day: date.getDate()
                                        readonly property int month: date.getMonth()
                                        readonly property int year: date.getFullYear()
                                        readonly property bool isToday: day === root.currentDay && month === root.currentMonth && year === root.currentYear
                                        readonly property bool isCurrentMonth: month === root.month

                                        height: root.dayHeight
                                        width: root.dayWidth

                                        Rectangle {
                                            id: backgroundRectangle
                                            anchors.fill: parent
                                            color: incidenceDropArea.containsDrag ?  Kirigami.Theme.positiveBackgroundColor :
                                                gridItem.isToday ? Kirigami.Theme.activeBackgroundColor :
                                                gridItem.isCurrentMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                            Kirigami.Theme.inherit: false
                                            Kirigami.Theme.colorSet: Kirigami.Theme.View

                                            DropArea {
                                                id: incidenceDropArea
                                                anchors.fill: parent
                                                z: 9999
                                                onDropped: if(root.isCurrentView) {
                                                    if (DateUtils.sameDay(gridItem.date, drop.source.occurrenceDate)) {
                                                        return;
                                                    }
                                                    const pos = mapToItem(root, backgroundRectangle.x, backgroundRectangle.y);
                                                    drop.source.caughtX = pos.x + root.listViewSpacing;
                                                    drop.source.caughtY = root.showDayIndicator ?
                                                        pos.y + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 1.5 :
                                                        pos.y;
                                                    drop.source.caught = true;

                                                    const incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
                                                    incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                    let sameTimeOnDate = new Date(gridItem.date);
                                                    sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                                                    const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                                                    CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source)
                                                }
                                            }
                                        }

                                        // Day number
                                        QQC2.Button {
                                            implicitHeight: dayNumberLayout.implicitHeight

                                            flat: true
                                            visible: root.showDayIndicator
                                            enabled: root.daysToShow > 1
                                            onClicked: CalendarUiUtils.openDayLayer(gridItem.date)
                                            activeFocusOnTab: isCurrentView

                                            anchors {
                                                top: parent.top
                                                right: parent.right
                                                left: parent.left
                                            }

                                            Accessible.name: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5 ? todayLabel.text.replace(/<b>/g, '').replace(/<\/b>/g, '') : gridItem.date.toLocaleDateString(Qt.locale(), Locale.LongFormat)

                                            contentItem: RowLayout {
                                                id: dayNumberLayout
                                                visible: root.showDayIndicator

                                                QQC2.Label {
                                                    id: todayLabel

                                                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                                    padding: Kirigami.Units.smallSpacing
                                                    text: i18n("<b>Today</b>")
                                                    renderType: Text.QtRendering
                                                    color: Kirigami.Theme.highlightColor
                                                    visible: gridItem.isToday && gridItem.width > Kirigami.Units.gridUnit * 5
                                                }
                                                QQC2.Label {
                                                    id: dateLabel

                                                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                                                    text: gridItem.date.toLocaleDateString(Qt.locale(), gridItem.day == 1 ?
                                                    "d MMM" : "d")
                                                    renderType: Text.QtRendering
                                                    padding: Kirigami.Units.smallSpacing
                                                    visible: root.showDayIndicator
                                                    color: gridItem.isToday ?
                                                        Kirigami.Theme.highlightColor :
                                                        (!gridItem.isCurrentMonth ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor)
                                                    font.bold: gridItem.isToday
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: foregroundLoader
        anchors.fill: parent
        asynchronous: !root.isCurrentView

        sourceComponent: Column {
            id: rootForegroundColumn

            spacing: root.spacing

            anchors {
                fill: parent
                topMargin: root.bgLoader.dayLabelsBar.height + root.spacing
                leftMargin: Calendar.Config.showWeekNumbers ? weekHeaderWidth + root.spacing : 0
            }

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

                    RowLayout {
                        width: parent.width
                        height: parent.height
                        spacing: root.spacing
                        Item {
                            id: dayDelegate

                            readonly property date startDate: weekDelegate.periodStartDate

                            Layout.fillWidth: true
                            Layout.fillHeight: true

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

                                onCountChanged: {
                                    root.numberOfLinesShown = count
                                }

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
                                        delegate: DayGridViewIncidenceDelegate {
                                            id: incidenceDelegate

                                            required property var modelData

                                            starts: incidenceDelegate.modelData.starts
                                            duration: incidenceDelegate.modelData.duration
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

                                DayTapHandler {
                                    id: listViewMenu

                                    function useGridSquareDate(type, root, globalPosition) {
                                        for (const i in root.children) {
                                            const child = root.children[i];
                                            const localPosition = child.mapFromGlobal(globalPosition.x, globalPosition.y);

                                            if(child.contains(localPosition) && child.gridSquareDate) {
                                                IncidenceEditorManager.openNewIncidenceEditorDialog(QQC2.ApplicationWindow.window, type, child.gridSquareDate);
                                            } else {
                                                useGridSquareDate(type, child, globalPosition);
                                            }
                                        }
                                    }

                                    onAddNewIncidence: useGridSquareDate(type, applicationWindow().contentItem, parent.mapToGlobal(clickX, clickY))
                                    onDeselect: CalendarUiUtils.appMain.incidenceInfoViewer.close()
                                }

                            }
                        }
                    }
                }
            }
        }
    }
}
