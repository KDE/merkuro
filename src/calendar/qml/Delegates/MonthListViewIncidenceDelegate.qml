// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

Kirigami.AbstractCard {
    id: incidenceCard

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

    contentItem: RowLayout {
        id: cardContents

        property color textColor: Calendar.LabelUtils.getIncidenceLabelColor(incidenceCard.modelData.color, scrollView.isDark)

        Kirigami.Icon {
            Layout.fillHeight: true
            source: incidenceCard.modelData.incidenceTypeIcon
            isMask: true
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.maximumWidth: Kirigami.Units.iconSizes.small
            Layout.maximumHeight: Kirigami.Units.iconSizes.small

            color: incidenceCard.isOpenOccurrence ?
                (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                cardContents.textColor
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            Layout.fillWidth: true

            QQC2.Label {
                Layout.fillWidth: true

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

            QQC2.Label {
                Layout.fillWidth: true

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
                    } else {
                        i18nc("Label for incidence in between multiday start/finish", "Runs All Day")
                    }
                }
                Component.onCompleted: if(implicitWidth > scrollView.maxTimeLabelWidth) scrollView.maxTimeLabelWidth = implicitWidth
                visible: !incidenceCard.modelData.allDay && !incidenceCard.modelData.todoCompleted
            }

            QQC2.Label {
                Layout.fillWidth: true

                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                text: i18nc("Location indicator for incidence. %1 is the location", "<b>Location</b>: %1", incidenceCard.modelData.location)
                visible: incidenceCard.modelData.location && !incidenceCard.modelData.todoCompleted
            }
            
            Text {
                Layout.fillWidth: true

                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                
                text: modelData.description
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 3
                
                visible: modelData.description && !incidenceCard.modelData.todoCompleted
            }
        }

        RowLayout {
            id: additionalIcons

            Layout.alignment: Qt.AlignTop

            visible: incidenceCard.modelData.hasReminders || modelData.recurs

            Kirigami.Icon {
                id: recurringIcon
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.maximumWidth: Kirigami.Units.iconSizes.small
                Layout.maximumHeight: Kirigami.Units.iconSizes.small
                source: "appointment-recurring"
                isMask: true
                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                visible: incidenceCard.modelData.recurs
            }
            Kirigami.Icon {
                id: reminderIcon
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.maximumWidth: Kirigami.Units.iconSizes.small
                Layout.maximumHeight: Kirigami.Units.iconSizes.small
                Layout.fillHeight: true
                source: "appointment-reminder"
                isMask: true
                color: incidenceCard.isOpenOccurrence ? (Calendar.LabelUtils.isDarkColor(incidenceCard.modelData.color) ? "white" : "black") :
                    cardContents.textColor
                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                visible: incidenceCard.modelData.hasReminders
            }
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
