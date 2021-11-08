// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar 1.0 as Kalendar
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

Rectangle {
    x: ((dayWidth + parentViewSpacing) * model.starts) + horizontalSpacing
    y: model.line * (Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing + verticalSpacing)
    z: 10
    width: ((dayWidth + parentViewSpacing) * model.duration) - (horizontalSpacing * 2) - parentViewSpacing // Account for spacing added to x and for spacing at end of line
    height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
    opacity: isOpenOccurrence || isInCurrentMonth ?
        1.0 : 0.5
    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    radius: Kirigami.Units.smallSpacing
    color: Qt.rgba(0,0,0,0)

    property real dayWidth: 0
    property real parentViewSpacing: 0
    property real horizontalSpacing: 0 // In between incidence spaces
    property real verticalSpacing: 0
    property string openOccurrenceId: ""
    property bool isOpenOccurrence: openOccurrenceId ?
        openOccurrenceId === model.incidenceId : false
    property bool reactToCurrentMonth: true
    readonly property bool isInCurrentMonth: reactToCurrentMonth && currentMonth ?
        model.endTime.getMonth() == root.month || model.startTime.getMonth() == root.month :
        true
    property bool isDark: false

    IncidenceBackground {
        id: incidenceBackground
        isOpenOccurrence: parent.isOpenOccurrence
        reactToCurrentMonth: parent.reactToCurrentMonth
        isInCurrentMonth: parent.isInCurrentMonth
        isDark: parent.isDark
    }

    RowLayout {
        id: incidenceContents
        clip: true
        property bool spaceRestricted: parent.width < Kirigami.Units.gridUnit * 5

        property color textColor: LabelUtils.getIncidenceLabelColor(model.color, root.isDark)

        function otherMonthTextColor(color) {
            if(isDark) {
                if(LabelUtils.getDarkness(color) >= 0.5) {
                    return Qt.lighter(color, 2);
                }
                return Qt.lighter(color, 1.5);
            }
            return Qt.darker(color, 3);
        }

        anchors {
            fill: parent
            leftMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            rightMargin: spaceRestricted ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
        }

        Kirigami.Icon {
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: height

            source: model.incidenceTypeIcon
            isMask: true
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(model.color) ? "white" : "black") :
                isInCurrentMonth ? incidenceContents.textColor :
                incidenceContents.otherMonthTextColor(model.color)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
            visible: !parent.spaceRestricted
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: model.text
            elide: parent.spaceRestricted ? Text.ElideNone : Text.ElideRight // Eliding takes up space
            font.weight: Font.Medium
            font.pointSize: parent.spaceRestricted ? Kirigami.Theme.smallFont.pointSize :
                Kirigami.Theme.defaultFont.pointSize
            renderType: Text.QtRendering
            color: isOpenOccurrence ? (LabelUtils.isDarkColor(model.color) ? "white" : "black") :
                isInCurrentMonth ? incidenceContents.textColor :
                incidenceContents.otherMonthTextColor(model.color)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
        }
    }

    IncidenceMouseArea {
        incidenceData: model
        collectionId: model.collectionId

        onViewClicked: viewIncidence(model, collectionData)
        onEditClicked: editIncidence(incidencePtr, collectionId)
        onDeleteClicked: deleteIncidence(incidencePtr, deleteDate)
        onTodoCompletedClicked: completeTodo(incidencePtr)
        onAddSubTodoClicked: root.addSubTodo(parentWrapper)
    }
}
