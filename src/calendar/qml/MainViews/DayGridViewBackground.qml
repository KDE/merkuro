// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.utils
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils


Column {
    id: root

    readonly property alias dayLabelsBar: dayLabelsBarComponent
    required property Component weekHeaderDelegate
    required property Component dayHeaderDelegate
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
                                        onDropped: if (root.isCurrentView) {
                                            if (DateUtils.sameDay(gridItem.date, drop.source.occurrenceDate)) {
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