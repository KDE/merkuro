// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

RowLayout {
    id: headerLayout

    property bool isDark: CalendarUiUtils.darkMode
    property var mode: Calendar.CalendarApplication.Event
    property var filterCollectionDetails: Calendar.Filter.collectionId >= 0 ?
        Calendar.CalendarManager.getCollectionDetails(Calendar.Filter.collectionId) : null

    visible: mode === Calendar.CalendarApplication.Todo || Calendar.Filter.tags.length > 0 || Calendar.Filter.collectionId > -1
    height: visible ? implicitHeight : 0

    spacing: Kirigami.Units.smallSpacing

    Connections {
        target: Calendar.CalendarManager
        function onCollectionColorsChanged() {
            // Trick into reevaluating filterCollectionDetails
            Calendar.Filter.tagsChanged();
        }
    }

    RowLayout {
        Layout.margins: Kirigami.Units.largeSpacing
        Kirigami.Heading {
            id: heading

            Layout.alignment: Qt.AlignVCenter
            width: implicitWidth

            text: headerLayout.mode !== Calendar.CalendarApplication.Todo ? i18n("Filtering by tags") : headerLayout.filterCollectionDetails && Calendar.Filter.collectionId > -1 ?
                headerLayout.filterCollectionDetails.displayName : i18n("All Tasks")
            font.weight: headerLayout.mode !== Calendar.CalendarApplication.Todo ? Font.Normal : Font.Bold
            color: headerLayout.mode === Calendar.CalendarApplication.Todo && headerLayout.filterCollectionDetails && Calendar.Filter.collectionId > -1 ?
                headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor
            elide: Text.ElideRight
            level: headerLayout.mode === Calendar.CalendarApplication.Todo ? 1 : 2
        }
        QQC2.ToolButton {
            Layout.alignment: Qt.AlignVCenter
            icon.name: "edit-reset"
            visible: headerLayout.mode === Calendar.CalendarApplication.Todo && Calendar.Filter.collectionId > -1
            onClicked: Calendar.Filter.collectionId = -1
        }
    }

    Flow {
        id: tagFlow

        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        Layout.bottomMargin: headerLayout.rows > 1 ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

        spacing: Kirigami.Units.smallSpacing
        layoutDirection: Qt.RightToLeft
        clip: true
        visible: Calendar.Filter.tags.length > 0

        Repeater {
            id: tagRepeater
            model: Calendar.Filter ? Calendar.Filter.tags : {}

            Calendar.Tag {
                id: filterTag

                text: modelData

                implicitWidth: itemLayout.implicitWidth > tagFlow.width ?
                    tagFlow.width : itemLayout.implicitWidth
                isHeading: true
                headingItem.color: headerLayout.mode === Calendar.CalendarApplication.Todo && headerLayout.filterCollectionDetails ?
                    headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor

                onClicked: Calendar.Filter.removeTag(modelData)
                actionIcon.name: "edit-delete-remove"
                actionText: i18n("Remove filtering tag")
            }
        }
    }

    Kirigami.Heading {
        id: numTasksHeading

        Layout.fillWidth: true
        Layout.rightMargin: Kirigami.Units.largeSpacing
        horizontalAlignment: Text.AlignRight

        function updateTasksCount() {
            if (headerLayout.mode === Calendar.CalendarApplication.Todo) {
                text = applicationWindow().pageStack.currentItem.incompleteView.model.rowCount();
            }
        }

        Connections {
            target: headerLayout.mode === Calendar.CalendarApplication.Todo ? applicationWindow().pageStack.currentItem.incompleteView.model : null
            function onRowsInserted() {
                numTasksHeading.updateTasksCount();
            }

            function onRowsRemoved() {
                numTasksHeading.updateTasksCount();
            }
        }

        text: headerLayout.mode === Calendar.CalendarApplication.Todo ? applicationWindow().pageStack.currentItem.incompleteView.model.rowCount() : ''
        font.weight: Font.Bold
        color: headerLayout.mode === Calendar.CalendarApplication.Todo && headerLayout.filterCollectionDetails && Calendar.Filter.collectionId > -1 ?
            headerLayout.filterCollectionDetails.color : Kirigami.Theme.textColor
        elide: Text.ElideRight
        visible: headerLayout.mode === Calendar.CalendarApplication.Todo
    }
}
