// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kirigamiaddons.delegates 1.0 as Delegates
import org.kde.kitemmodels 1.0

import org.kde.merkuro.calendar 1.0 as Calendar
import org.kde.merkuro.utils 1.0
import "dateutils.js" as DateUtils
import "labelutils.js" as LabelUtils

ListView {
    id: root

    // We need to store a copy of opened incidence data or we will lose it as we scroll the listviews.
    function viewAndRetainTodoData(todoData, incidenceItem) {
        retainedTodoData = {
            incidencePtr: todoData.incidencePtr,
            incidenceId: todoData.incidenceId,
            text: todoData.text,
            color: todoData.color,
            startTime: todoData.startTime,
            endTime: todoData.endTime,
            allDay: todoData.allDay,
            durationString: todoData.durationString
        };
        CalendarUiUtils.setUpView(retainedTodoData, incidenceItem);
    }

    property var retainedTodoData: ({})
    property var retainedCollectionData: ({})

    property date currentDate: new Date()
    property var filterCollectionDetails

    property int showCompleted: Calendar.TodoSortFilterProxyModel.ShowAll
    property int sortBy: Calendar.TodoSortFilterProxyModel.SummaryColumn
    property bool ascendingOrder: false
    property bool dragDropEnabled: true

    readonly property bool isDark: CalendarUiUtils.darkMode

    currentIndex: -1
    clip: true

    section {
        criteria: sortBy === Calendar.TodoSortFilterProxyModel.SummaryColumn ?
            ViewSection.FirstCharacter : ViewSection.FullString
        property: switch(sortBy) {
            case Calendar.TodoSortFilterProxyModel.PriorityColumn:
                return "topMostParentPriority";
            case Calendar.TodoSortFilterProxyModel.DueDateColumn:
                return "topMostParentDueDate";
            case Calendar.TodoSortFilterProxyModel.SummaryColumn:
            default:
                return "topMostParentSummary";
        }
        delegate: Kirigami.ListSectionHeader {
            id: listSection

            readonly property bool dateSort: root.sortBy === Calendar.TodoSortFilterProxyModel.DueDateColumn
            readonly property bool isOverdue: dateSort && section === i18n("Overdue")
            readonly property bool isToday: dateSort && section === i18n("Today")

            text: {
                switch(root.sortBy) {
                    case Calendar.TodoSortFilterProxyModel.PriorityColumn:
                        return section !== "--" ? i18n("Priority %1", section) : i18n("No set priority");
                    case Calendar.TodoSortFilterProxyModel.DueDateColumn:
                    case Calendar.TodoSortFilterProxyModel.SummaryColumn:
                    default:
                        return section;
                }
            }

            contentItem: RowLayout {
                id: rowLayout
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    Layout.fillWidth: rowLayout.children.length === 1
                    Layout.alignment: Qt.AlignVCenter

                    opacity: 0.7
                    level: 5
                    type: Kirigami.Heading.Primary
                    text: listSection.text
                    elide: Text.ElideRight

                    font.weight: Font.Bold
                    color: isOverdue ? Kirigami.Theme.negativeTextColor : isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    MouseArea {
        id: incidenceDeselectorMouseArea
        anchors.fill: parent
        enabled: !Kirigami.Settings.isMobile
        parent: background
        onClicked: CalendarUiUtils.appMain.incidenceInfoViewer.close()
        propagateComposedEvents: true
    }

    Kirigami.PlaceholderMessage {
        id: allTasksPlaceholderMessage
        anchors.centerIn: parent
        visible: (!Calendar.Filter.collectionId || Calendar.Filter.collectionId < 0) && Calendar.CalendarManager.enabledTodoCollections.length === 0 && parent.count === 0
        text: i18n("No task calendars enabled.")
    }

    Kirigami.PlaceholderMessage {
        id: collectionPlaceholderMessage
        anchors.centerIn: parent
        visible: Calendar.Filter && Calendar.Filter.collectionId >= 0 && !Calendar.CalendarManager.enabledTodoCollections.includes(Calendar.Filter.collectionId) && parent.count === 0
        text: i18n("Calendar is not enabled")
        helpfulAction: Kirigami.Action {
            icon.name: "gtk-yes"
            text: i18n("Enable")
            onTriggered: Calendar.CalendarManager.toggleCollection(root.filterCollectionDetails.id)
        }
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        visible: parent.count === 0 && !allTasksPlaceholderMessage.visible && !collectionPlaceholderMessage.visible
        text: root.showCompleted === Calendar.TodoSortFilterProxyModel.ShowCompleteOnly ?
            i18n("No tasks completed") : i18n("No tasks left to complete")
        helpfulAction: Kirigami.Action {
            text: i18n("Create")
            icon.name: "list-add"
            onTriggered: CalendarUiUtils.setUpAdd(Calendar.IncidenceWrapper.TypeTodo, new Date(), Calendar.Filter.collectionId);
        }
    }

    model: KDescendantsProxyModel {
        model: Calendar.TodoSortFilterProxyModel {
            id: todoModel
            calendar: Calendar.CalendarManager.calendar
            incidenceChanger: Calendar.CalendarManager.incidenceChanger
            filterObject: Calendar.Filter
            showCompleted: root.showCompleted
            sortBy: root.sortBy
            sortAscending: root.ascendingOrder
            showCompletedSubtodosInIncomplete: Calendar.Config.showCompletedSubtodos
        }
    }

    delegate: Delegates.RoundedTreeDelegate {
        id: listItem

        readonly property bool validEndDt: !isNaN(model.endTime.getTime())

        property alias mouseArea: mouseArea
        property bool repositionAnimationEnabled: false
        property bool caught: false
        property real caughtX: x
        property real caughtY: y

        required property var model

        required property string displayDueDate
        required property bool isOverdue
        required property int percent
        required property bool todoCompleted
        required property bool isReadOnly
        required property var color
        required property var incidencePtr
        required property var collectionId
        required property date startTime
        required property date endTime
        required property var priority
        required property var todoCategories
        required property bool recurs

        objectName: "taskDelegate"

        Drag.active: mouseArea.drag.active
        Drag.hotSpot.x: mouseArea.mouseX
        Drag.hotSpot.y: mouseArea.mouseY

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.highlightColor: LabelUtils.getIncidenceDelegateBackgroundColor(color, root.isDark)

        Behavior on x {
            enabled: repositionAnimationEnabled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            enabled: repositionAnimationEnabled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        states: [
            State {
                when: listItem.mouseArea.drag.active
                ParentChange { target: listItem; parent: applicationWindow().contentItem }
                PropertyChanges { target: listItem; highlighted: true; z: 9999 }
                PropertyChanges { target: applicationWindow().contentItem; clip: false }
                PropertyChanges { target: applicationWindow().globalDrawer; z: -1 }
            },
            State {
                when: listItem.caught
                ParentChange { target: listItem; parent: root }
                PropertyChanges {
                    target: listItem
                    repositionAnimationEnabled: true
                    x: caughtX
                    y: caughtY
                }
            }
        ]

        onClicked: root.viewAndRetainTodoData(model, listItem);

        Accessible.description: if (listItem.validEndDt) {
            displayDueDate + isOverdue ? i18n(" , is overdue") : ""
        } else {
            ''
        }

        contentItem: IncidenceMouseArea {
            id: mouseArea

            implicitHeight: todoItemContents.implicitHeight + (Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing)

            incidenceData: listItem.model
            collectionId: listItem.collectionId
            anchors.fill: null

            preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile

            drag.target: !Kirigami.Settings.isMobile && !listItem.isReadOnly && root.dragDropEnabled ? listItem : undefined
            onReleased: listItem.Drag.drop()

            onViewClicked: listItem.clicked()
            onEditClicked: CalendarUiUtils.setUpEdit(listItem.incidencePtr)
            onDeleteClicked: CalendarUiUtils.setUpDelete(listItem.incidencePtr,
                                                         listItem.endTime ? listItem.endTime :
                                                                         listItem.startTime ? listItem.startTime :
                                                                                           null)
            onTodoCompletedClicked: listItem.model.checked = listItem.model.checked === 0 ? 2 : 0
            onAddSubTodoClicked: CalendarUiUtils.setUpAddSubTodo(parentWrapper)

            GridLayout {
                id: todoItemContents

                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.smallSpacing
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                columns: 4
                rows: 2
                columnSpacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing * 2 : Kirigami.Units.largeSpacing

                TodoCheckBox {
                    Layout.row: 0
                    Layout.column: 0
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 || recurIcon.visible || dateLabel.visible ? 1 : 2

                    todoCompleted: listItem.todoCompleted
                    todoCompletion: listItem.percent
                    todoPtr: listItem.incidencePtr
                    color: listItem.color
                }

                QQC2.Label {
                    id: nameLabel
                    Layout.row: 0
                    Layout.column: 1
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible) ? 2 : 1
                    Layout.rowSpan: occurrenceLayout.visible ? 1 : 2
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: listItem.model.text
                    font.strikeout: listItem.todoCompleted
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                }

                Flow {
                    id: tagFlow
                    Layout.fillWidth: true
                    Layout.minimumWidth: tagsRepeater.count > 0 ? Math.min(tagsRepeater.itemAt(0).implicitWidth, Kirigami.Units.gridUnit * 6) : -1
                    Layout.row: root.width < Kirigami.Units.gridUnit * 28 && (recurIcon.visible || dateLabel.visible || priorityLayout.visible) ? 1 : 0
                    Layout.column: 2
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
                    Layout.columnSpan: root.width < Kirigami.Units.gridUnit * 28 ? 2 : 1
                    Layout.rightMargin: Kirigami.Units.largeSpacing

                    layoutDirection: Qt.RightToLeft
                    spacing: Kirigami.Units.largeSpacing

                    Repeater {
                        id: tagsRepeater
                        model: listItem.todoCategories // From todoModel

                        Tag {
                            width: implicitWidth > tagFlow.width ? tagFlow.width : implicitWidth
                            text: modelData
                            showAction: false
                        }
                    }
                }

                RowLayout {
                    id: priorityLayout
                    Layout.row: 0
                    Layout.column: 3
                    Layout.rowSpan: root.width < Kirigami.Units.gridUnit * 28 ? 1 : 2
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    spacing: 0
                    visible: listItem.priority > 0

                    Kirigami.Icon {
                        Layout.maximumHeight: priorityLabel.height
                        source: "emblem-important-symbolic"
                    }
                    QQC2.Label {
                        id: priorityLabel
                        text: listItem.priority
                    }
                }

                RowLayout {
                    id: occurrenceLayout

                    Layout.row: 1
                    Layout.column: 1
                    Layout.fillWidth: true

                    visible: dateLabel.visible || recurIcon.visible

                    QQC2.Label {
                        id: dateLabel

                        text: listItem.displayDueDate
                        color: listItem.isOverdue ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        visible: listItem.validEndDt
                    }
                    Kirigami.Icon {
                        id: recurIcon
                        source: "task-recurring"
                        visible: listItem.recurs
                        Layout.maximumHeight: parent.height
                    }
                }
            }
        }
    }
}
