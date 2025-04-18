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

    readonly property alias dayLabelsBar: dayLabelsBarComponent
    required property Item parentGridView

    required property date startDate
    required property int month

    readonly property date currentDate: Calendar.DateTimeState.currentDate
    // Getting the components once makes this faster when we need them repeatedly
    readonly property int currentDay: currentDate.getDate()
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()

    required property real dayWidth
    required property real dayHeight
    required property int daysToShow
    required property int daysPerRow
    required property int numberOfRows
    required property int listViewSpacing

    required property bool isCurrentView
    required property bool showDayIndicator

    required property double weekHeaderWidth

    Component.onCompleted: {
        if (Calendar.Config.showHolidaysInCalendarViews) {
            Calendar.HolidayModel.loadDateRange(startDate, daysToShow)
        }
    }

    Connections {
        target: Calendar.Config

        function onShowHolidaysInCalendarViewsChanged(): void {
            if (Calendar.Config.showHolidaysInCalendarViews) {
                Calendar.HolidayModel.loadDateRange(root.startDate, root.daysToShow)
            }
        }
    }

    anchors.fill: parent

    Calendar.DayLabelsBar {
        id: dayLabelsBarComponent

        startDate: root.startDate
        dayWidth: root.dayWidth
        daysToShow: root.daysPerRow
        spacing: root.spacing

        anchors {
            leftMargin: Calendar.Config.showWeekNumbers ? root.weekHeaderWidth + root.spacing : 0
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

                    property date startDate: Calendar.Utils.addDaysToDate(root.startDate, weekRow.index * 7)

                    active: Calendar.Config.showWeekNumbers
                    visible: Calendar.Config.showWeekNumbers

                    Layout.preferredWidth: root.weekHeaderWidth
                    Layout.fillHeight: true

                    sourceComponent: QQC2.Label {
                        padding: Kirigami.Units.smallSpacing
                        verticalAlignment: Qt.AlignTop
                        horizontalAlignment: Qt.AlignHCenter
                        text: Calendar.Utils.weekNumber(weekHeader.startDate)
                        background: Rectangle {
                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.backgroundColor
                        }
                    }
                }

                Item {
                    id: dayDelegate

                    property date startDate: Calendar.Utils.addDaysToDate(root.startDate, weekRow.index * 7)

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

                                Kirigami.Theme.colorSet: Kirigami.Theme.View

                                required property var modelData

                                readonly property date gridSquareDate: date
                                readonly property date date: Calendar.DateUtils.addDaysToDate(dayDelegate.startDate, modelData)
                                readonly property int day: date.getDate()
                                readonly property int month: date.getMonth()
                                readonly property int year: date.getFullYear()
                                readonly property color bgColor: {
                                    if (Calendar.Config.showHolidaysInCalendarViews && gridItem.isHoliday) {
                                        Kirigami.Theme.negativeBackgroundColor
                                    } else if (incidenceDropArea.containsDrag) {
                                        Kirigami.Theme.positiveBackgroundColor
                                    } else if (gridItem.isToday) {
                                        Kirigami.Theme.activeBackgroundColor
                                    } else if (gridItem.isCurrentMonth) {
                                        Kirigami.Theme.backgroundColor
                                    } else {
                                        Kirigami.Theme.alternateBackgroundColor
                                    }
                                }

                                readonly property bool isToday: day === root.currentDay && month === root.currentMonth && year === root.currentYear
                                readonly property bool isCurrentMonth: month === root.month
                                readonly property string formatedDate: Qt.formatDate(gridItem.date, 'yyyy-MM-dd')
                                readonly property bool isHoliday: Calendar.Config.showHolidaysInCalendarViews && formatedDate in Calendar.HolidayModel.holidays
                                readonly property string holidayText: {
                                    if (!isHoliday) {
                                        return '';
                                    }
                                    const holidays = Calendar.HolidayModel.holidays[formatedDate];
                                    return holidays.join("\n");
                                }

                                height: root.dayHeight
                                width: root.dayWidth

                                Rectangle {
                                    id: backgroundRectangle
                                    anchors.fill: parent
                                    color: gridItem.bgColor

                                    Kirigami.Theme.inherit: false
                                    Kirigami.Theme.colorSet: Kirigami.Theme.View

                                    DropArea {
                                        id: incidenceDropArea
                                        anchors.fill: parent
                                        z: 9999
                                        onDropped: drop => {
                                            if (root.isCurrentView) {
                                                if (Calendar.DateUtils.sameDay(gridItem.date, drop.source.occurrenceDate)) {
                                                    return;
                                                }
                                                const pos = mapToItem(parentGridView, backgroundRectangle.x, backgroundRectangle.y);
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
                                                Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source)
                                            }
                                        }
                                    }
                                }

                                // Day number
                                QQC2.Button {
                                    implicitHeight: dayNumberLayout.implicitHeight

                                    flat: true
                                    visible: root.showDayIndicator
                                    enabled: root.daysToShow > 1
                                    onClicked: Calendar.CalendarUiUtils.openDayLayer(gridItem.date)
                                    activeFocusOnTab: root.isCurrentView

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
                                            id: holidayLabel

                                            Layout.fillWidth: true
                                            visible: Calendar.Config.showHolidaysInCalendarViews
                                            text: gridItem.holidayText
                                            color: Kirigami.Theme.negativeTextColor
                                            font.bold: true
                                            elide: Text.ElideRight
                                            padding: Kirigami.Units.smallSpacing
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
