// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

/**
 * This is the schedule view
 */
QQC2.ScrollView {
    id: scrollView

    required property var openOccurrence
    required property date startDate
    required property bool dragDropEnabled
    required property bool isCurrentItem

    readonly property int daysInMonth: new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0).getDate()

    property real savedYScrollPos: 0

    property real maxTimeLabelWidth: 0

    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    readonly property bool isDark: Calendar.CalendarUiUtils.darkMode

    contentWidth: availableWidth
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    function addIncidence(type, eventDate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.IncidenceEditorManager.openNewIncidenceEditorDialog(QQC2.ApplicationWindow.window, type, eventDate);
    }

    function viewIncidence(modelData, incidenceItem) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpView(modelData, incidenceItem);
    }

    function deleteIncidence(incidencePtr, deleteDate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpDelete(incidencePtr, deleteDate);
    }

    function completeTodo(incidencePtr) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.completeTodo(incidencePtr);
    }

    function moveIncidence(startOffset, occurrenceDate, incidenceWrapper, caughtDelegate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate);
    }

    function moveToSelected() {
        if (savedYScrollPos > 0) {
            QQC2.ScrollBar.vertical.position = savedYScrollPos;
            return;
        }

        const currentDate = Calendar.DateTimeState.currentDate;
        if (currentDate.getDate() > 1 && currentDate.getMonth() === month && currentDate.getFullYear() === year) {
            scheduleListView.positionViewAtIndex(currentDate.getDate() - 1, ListView.Beginning);
        } else {
            scheduleListView.positionViewAtBeginning()
        }
    }

    ListView {
        id: scheduleListView

        highlightRangeMode: ListView.ApplyRange

        onCountChanged: if(scrollView.initialMonth) scrollView.moveToSelected()
        clip: true

        model: Calendar.MultiDayIncidenceModel {
           periodLength: 1
           showTodos: Calendar.Config.showTodosInCalendarViews
           showSubTodos: Calendar.Config.showSubtodosInCalendarViews
           active: scrollView.isCurrentItem
           model: Calendar.IncidenceOccurrenceModel {
               start: scrollView.startDate
               length: scrollView.daysInMonth
               calendar: Calendar.CalendarManager.calendar
               filter: Calendar.Filter
           }
       }

        delegate: Rectangle {
            id: backgroundRectangle

            required property var incidences
            required property var periodStartDate
            required property int index

            width: dayColumn.width
            height: index === scheduleListView.count - 1 ? dayColumn.height + Kirigami.Units.largeSpacing : dayColumn.height
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: incidenceDropArea.containsDrag ? Kirigami.Theme.positiveBackgroundColor :
                dayGrid.isToday ? Kirigami.Theme.activeBackgroundColor :
                Kirigami.Theme.backgroundColor

            Calendar.DayTapHandler {
                id: dayTapHandler
                addDate: backgroundRectangle.periodStartDate
                onDeselect: Calendar.CalendarUiUtils.appMain.incidenceInfoViewer.close()
            }

            DropArea {
                id: incidenceDropArea
                anchors.fill: parent
                z: 9999
                onDropped: drop => {
                    if(scrollView.isCurrentItem) {
                        if (Calendar.DateUtils.sameDay(dayTapHandler.addDate, drop.source.occurrenceDate)) {
                            return;
                        }
                        scrollView.savedYScrollPos = scrollView.QQC2.ScrollBar.vertical.visualPosition;

                        const pos = mapToItem(scrollView, backgroundRectangle.x, backgroundRectangle.y);
                        drop.source.caughtX = pos.x + dayGrid.dayLabelWidth + Kirigami.Units.largeSpacing;
                        drop.source.caughtY = pos.y + dayColumn.spacing + Kirigami.Units.largeSpacing;
                        drop.source.caught = true;

                        const incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
                        incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                        let sameTimeOnDate = new Date(dayTapHandler.addDate);
                        sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                        const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                        scrollView.moveIncidence(offset, drop.source.occurrenceDate, incidenceWrapper, drop.source);
                    }
                }
            }

            ColumnLayout {
                // Tip: do NOT hide an entire delegate.
                // This will very much screw up use of positionViewAtIndex.

                id: dayColumn
                width: scheduleListView.width

                Kirigami.ListSectionHeader {
                    id: weekHeading

                    Layout.fillWidth: true
                    Layout.bottomMargin: -dayColumn.spacing // Remove default spacing, bring week header right down to day square

                    text: {
                        const daysToWeekEnd = 6;

                        const nextDayMaxDiff = (backgroundRectangle.periodStartDate.getDate() - (backgroundRectangle.index + 1)) + daysToWeekEnd;
                        const nextDayMaxDate = backgroundRectangle.periodStartDate.getDate() + nextDayMaxDiff;
                        const nextDayDate = Math.min(nextDayMaxDate, scrollView.daysInMonth);

                        const nextDay = new Date(backgroundRectangle.periodStartDate.getFullYear(), backgroundRectangle.periodStartDate.getMonth(), nextDayDate);
                        return backgroundRectangle.periodStartDate.toLocaleDateString(Qt.locale(), "dddd <b>dd</b>") + "–" + nextDay.toLocaleDateString(Qt.locale(), "dddd <b>dd</b> MMMM");
                    }
                    Accessible.name: text.replace(/<\/?b>/g, '')
                    visible: Calendar.Config.showWeekHeaders &&
                        backgroundRectangle.periodStartDate !== undefined &&
                        (backgroundRectangle.periodStartDate.getDay() === Qt.locale().firstDayOfWeek || backgroundRectangle.index === 0)
                }

                Kirigami.Separator {
                    id: topSeparator
                    Layout.fillWidth: true
                    z: 1
                }

                // Day + incidences
                GridLayout {
                    id: dayGrid

                    columns: 2
                    rows: 2

                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing

                    property real dayLabelWidth: Kirigami.Units.gridUnit * 4
                    property bool isToday: new Date(backgroundRectangle.periodStartDate).setHours(0,0,0,0) === new Date().setHours(0,0,0,0)

                    QQC2.Button {
                        id: dayButton
                        Layout.fillHeight: true
                        Layout.maximumWidth: dayGrid.dayLabelWidth
                        Layout.minimumWidth: dayGrid.dayLabelWidth
                        padding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.largeSpacing

                        flat: true
                        onClicked: Calendar.CalendarUiUtils.openDayLayer(backgroundRectangle.periodStartDate)

                        property Item smallDayLabel: QQC2.Label {
                            id: smallDayLabel

                            Layout.alignment: Qt.AlignVCenter
                            width: dayButton.width
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter

                            visible: !cardsColumn.visible
                            wrapMode: Text.Wrap
                            text: backgroundRectangle.periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                            color: Kirigami.Theme.disabledTextColor
                        }


                        property Item largeDayLabel: Kirigami.Heading {
                            id: largeDayLabel

                            width: dayButton.width
                            Layout.alignment: Qt.AlignTop
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignTop

                            level: dayGrid.isToday ? 1 : 3
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            text: backgroundRectangle.periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                        }


                        contentItem: backgroundRectangle.incidences.length || dayGrid.isToday ? largeDayLabel : smallDayLabel
                    }

                    QQC2.Label {
                        id: emptyDayText

                        Layout.alignment: Qt.AlignVCenter
                        visible: !cardsColumn.visible
                        text: i18nc("Date has no events or tasks set", "Clear day.")
                        color: Kirigami.Theme.disabledTextColor
                    }

                    ColumnLayout {
                        id: cardsColumn

                        Layout.fillWidth: true
                        visible: backgroundRectangle.incidences.length || dayGrid.isToday

                        Kirigami.AbstractCard {
                            id: suggestCard

                            Layout.fillWidth: true

                            showClickFeedback: true
                            visible: !backgroundRectangle.incidences.length && dayGrid.isToday

                            contentItem: QQC2.Label {
                                property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")
                                text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                wrapMode: Text.Wrap
                            }

                            onClicked: scrollView.addIncidence(Calendar.IncidenceWrapper.TypeEvent, backgroundRectangle.periodStartDate)
                        }

                        Repeater {
                            model: backgroundRectangle.incidences
                            delegate: Repeater {
                                id: incidencesRepeater

                                required property var modelData

                                model: modelData

                                delegate: Kirigami.AbstractCard {
                                    id: incidenceCard

                                    required property var modelData

                                    property real paddingSize: Kirigami.Settings.isMobile ?
                                        Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
                                    property bool isOpenOccurrence: scrollView.openOccurrence ?
                                        scrollView.openOccurrence.incidenceId === modelData.incidenceId : false
                                    property bool multiday: modelData.startTime.getDate() !== modelData.endTime.getDate()
                                    property int incidenceDays: Calendar.DateUtils.fullDaysBetweenDates(modelData.startTime, modelData.endTime)
                                    property int dayOfMultidayIncidence: Calendar.DateUtils.fullDaysBetweenDates(modelData.startTime, periodStartDate)

                                    property alias mouseArea: incidenceMouseArea
                                    property var incidencePtr: modelData.incidencePtr
                                    property date occurrenceDate: modelData.startTime
                                    property date occurrenceEndDate: modelData.endTime
                                    property bool repositionAnimationEnabled: false
                                    property bool caught: false
                                    property real caughtX: 0
                                    property real caughtY: 0

                                    Drag.active: mouseArea.drag.active
                                    Drag.hotSpot.x: mouseArea.mouseX
                                    Drag.hotSpot.y: mouseArea.mouseY

                                    Layout.fillWidth: true
                                    topPadding: paddingSize
                                    bottomPadding: paddingSize

                                    showClickFeedback: true
                                    background: Calendar.IncidenceDelegateBackground {
                                        id: incidenceDelegateBackground
                                        isOpenOccurrence: incidenceCard.isOpenOccurrence
                                        isDark: scrollView.isDark
                                    }

                                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }

                                    // Drag reposition animations -- when the incidence goes to the section of the view
                                    Behavior on x {
                                        enabled: incidenceCard.repositionAnimationEnabled
                                        NumberAnimation {
                                            duration: Kirigami.Units.shortDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on y {
                                        enabled: incidenceCard.repositionAnimationEnabled
                                        NumberAnimation {
                                            duration: Kirigami.Units.shortDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    states: [
                                        State {
                                            when: incidenceCard.mouseArea.drag.active
                                            ParentChange { target: incidenceCard; parent: scrollView }
                                            PropertyChanges { target: incidenceCard; isOpenOccurrence: true }
                                        },
                                        State {
                                            when: incidenceCard.caught
                                            ParentChange { target: incidenceCard; parent: scrollView }
                                            PropertyChanges {
                                                target: incidenceCard
                                                repositionAnimationEnabled: true
                                                x: caughtX
                                                y: caughtY
                                                opacity: 0
                                            }
                                        }
                                    ]

                                    contentItem: GridLayout {
                                        id: cardContents

                                        columns: scrollView.isLarge ? 3 : 2
                                        rows: scrollView.isLarge ? 1 : 2

                                        property color textColor: Calendar.LabelUtils.getIncidenceLabelColor(incidenceCard.modelData.color, scrollView.isDark)

                                        RowLayout {
                                            Kirigami.Icon {
                                                Layout.fillHeight: true
                                                source: incidenceCard.modelData.incidenceTypeIcon
                                                isMask: true
                                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                                Layout.maximumWidth: Kirigami.Units.iconSizes.medium
                                                Layout.maximumHeight: Kirigami.Units.iconSizes.medium

                                                color: incidenceCard.isOpenOccurrence ?
                                                    (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.column: 0
                                                Layout.row: 0
                                                Layout.columnSpan: scrollView.isLarge ? 2 : 1

                                                color: incidenceCard.isOpenOccurrence ?
                                                    (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                text: {
                                                    if(incidenceCard.multiday) {
                                                        return i18nc("%1 is the name of the event", "%1 (Day %2 of %3)", incidenceCard.modelData.text, incidenceCard.dayOfMultidayIncidence, incidenceCard.incidenceDays);
                                                    } else {
                                                        return modelData.text;
                                                    }
                                                }
                                                elide: Text.ElideRight
                                                font.weight: Font.Medium
                                                font.strikeout: incidenceCard.modelData.todoCompleted
                                            }
                                        }

                                        RowLayout {
                                            id: additionalIcons

                                            Layout.column: 1
                                            Layout.row: 0

                                            visible: incidenceCard.modelData.hasReminders || modelData.recurs

                                            Kirigami.Icon {
                                                id: recurringIcon
                                                Layout.fillHeight: true
                                                source: "appointment-recurring"
                                                isMask: true
                                                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                visible: incidenceCard.modelData.recurs
                                            }
                                            Kirigami.Icon {
                                                id: reminderIcon
                                                Layout.fillHeight: true
                                                source: "appointment-reminder"
                                                isMask: true
                                                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                                                    cardContents.textColor
                                                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                visible: incidenceCard.modelData.hasReminders
                                            }
                                        }


                                        QQC2.Label {
                                            Layout.fillHeight: true
                                            // This way all the icons are aligned
                                            Layout.maximumWidth: scrollView.maxTimeLabelWidth
                                            Layout.minimumWidth: scrollView.maxTimeLabelWidth
                                            Layout.column: scrollView.isLarge ? 2 : 0
                                            Layout.row: scrollView.isLarge ? 0 : 1

                                            horizontalAlignment: scrollView.isLarge ? Text.AlignRight : Text.AlignLeft
                                            color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                                                cardContents.textColor
                                            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                            text: {
                                                if (incidenceCard.modelData.allDay) {
                                                    i18n("Runs all day")
                                                } else if (modelData.startTime.getTime() === modelData.endTime.getTime()) {
                                                    modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
                                                } else if (!incidenceCard.multiday) {
                                                    i18nc("Displays times between incidence start and end", "%1 - %2",
                                                          modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat), modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (incidenceCard.dayOfMultidayIncidence === 1) {
                                                    i18n("Starts at %1", modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else if (incidenceCard.dayOfMultidayIncidence === incidenceCard.incidenceDays) {
                                                    i18n("Ends at %1", modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                                                } else { // In between multiday start/finish
                                                    i18n("Runs All Day")
                                                }
                                            }
                                            Component.onCompleted: if(implicitWidth > scrollView.maxTimeLabelWidth) scrollView.maxTimeLabelWidth = implicitWidth
                                        }
                                    }

                                    Calendar.IncidenceMouseArea {
                                        id: incidenceMouseArea

                                        preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
                                        incidenceData: incidenceCard.modelData
                                        collectionId: incidenceCard.modelData.collectionId

                                        drag.target: !Kirigami.Settings.isMobile && !incidenceCard.modelData.isReadOnly && scrollView.dragDropEnabled ? incidenceCard : undefined
                                        onReleased: incidenceCard.Drag.drop()

                                        onViewClicked: scrollView.viewIncidence(incidenceCard.modelData, incidenceCard)
                                        onDeleteClicked: (incidencePtr, deleteDate) => scrollView.deleteIncidence(incidenceCard.incidencePtr, deleteDate)
                                        onTodoCompletedClicked: scrollView.completeTodo(incidenceCard.incidencePtr)
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
