// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.merkuro.calendar

Item {
    id: root
    property var incidenceWrapper: modelData
    property var collectionData: CalendarManager.getCollectionDetails(incidenceWrapper.collectionId)

    Layout.fillWidth: true

    IncidenceMouseArea {
        id: mouseArea
        incidenceData: CalendarUiUtils.fakeModelDataFromIncidenceWrapper(incidenceWrapper)
        collectionId: incidenceWrapper.collectionId

        preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
        // TODO: Add drag support
        //drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && incidenceDelegate.dragDropEnabled ? parent : undefined
        //onReleased: parent.Drag.drop()

        onViewClicked: CalendarUiUtils.setUpView(incidenceData, root)
        onDeleteClicked: CalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
        onTodoCompletedClicked: CalendarUiUtils.completeTodo(incidencePtr)
    }

    IncidenceDelegateBackground {
        color: LabelUtils.getIncidenceDelegateBackgroundColor(collectionData.color, CalendarUiUtils.darkMode)
    }

    RowLayout {
        id: incidenceContents
        clip: true
        property color textColor: LabelUtils.getIncidenceLabelColor(collectionData.color, CalendarUiUtils.darkMode)

        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing

        Rectangle {
            width: todoCheckBox.implicitWidth + 3
            height: todoCheckBox.implicitWidth + 3
            color: Kirigami.Theme.backgroundColor
            radius: 100

            TodoCheckBox {
                id: todoCheckBox

                // anchors.centerIn doesn't really work correctly here so we position manually
                x: (parent.width / 2) - (implicitWidth / 2)
                y: parent.height / 2 - height / 2
                todoCompleted: incidenceWrapper.todoCompleted
                todoCompletion: incidenceWrapper.todoPercentComplete
                todoPtr: incidenceWrapper.incidencePtr
                color: collectionData.color
                visible: incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
            }
        }

        Kirigami.Icon {
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: height

            source: incidenceWrapper.incidenceIconName
            isMask: true
            color: incidenceContents.textColor
            visible: incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: incidenceWrapper.summary
            elide: Text.ElideRight
            font.weight: Font.Medium
            font.strikeout: incidenceWrapper.todoCompleted
            color: incidenceContents.textColor
        }

        Kirigami.Icon {
            id: recurringIcon
            Layout.fillHeight: true
            source: "appointment-recurring"
            isMask: true
            color: incidenceContents.textColor
            visible: incidenceWrapper.recurrenceData.type
        }
        Kirigami.Icon {
            id: reminderIcon
            Layout.fillHeight: true
            source: "appointment-reminder"
            isMask: true
            color: incidenceContents.textColor
            visible: incidenceWrapper.remindersModel.rowCount() > 0
        }

        QQC2.Label {
            text: incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo ?
                incidenceWrapper.incidenceEnd.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) :
                incidenceWrapper.incidenceStart.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
            color: incidenceContents.textColor
            visible: !incidenceWrapper.allDay
        }
    }
}
