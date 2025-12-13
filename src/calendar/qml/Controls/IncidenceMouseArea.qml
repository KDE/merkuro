// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar as Calendar

MouseArea {
    id: mouseArea

    signal viewClicked(var incidenceData)
    signal deleteClicked(var incidencePtr, date deleteDate)
    signal todoCompletedClicked(var incidencePtr)

    property double clickX
    property double clickY
    property var incidenceData
    property int collectionId
    property var collectionDetails

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            collectionDetails = Calendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
            viewClicked(incidenceData);
        } else if (mouse.button === Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            incidenceActions.createObject(mouseArea, {}).popup();
        }
    }
    onPressAndHold: if(Kirigami.Settings.isMobile) {
        clickX = mouseX;
        clickY = mouseY;
        incidenceActions.createObject(mouseArea, {}).popup();
    }
    onDoubleClicked: {
        collectionDetails = Calendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
        Calendar.IncidenceEditorManager.openEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, incidenceData.incidencePtr)
    }

    Component {
        id: incidenceActions
        Components.ConvergentContextMenu {
            id: actionsPopup

            Component.onCompleted: if(mouseArea.collectionId && !mouseArea.collectionDetails) {
                mouseArea.collectionDetails = Calendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
            }

            QQC2.Action {
                icon.name: "dialog-icon-preview"
                text: i18n("View")
                onTriggered: viewClicked(incidenceData);
            }

            QQC2.Action {
                icon.name: "edit-entry"
                text: i18n("Edit")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onTriggered: () => {
                    Calendar.IncidenceEditorManager.openEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, incidenceData.incidencePtr)
                }
            }

            QQC2.Action {
                icon.name: "edit-delete"
                text:i18n("Delete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onTriggered: deleteClicked(incidenceData.incidencePtr, incidenceData.startTime)
            }

            Kirigami.Action {
                separator: true
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            }

            Kirigami.Action {
                icon.name: "task-complete"
                text: incidenceData.todoCompleted ? i18n("Mark Task as Incomplete") : i18n("Mark Task as Complete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onTriggered: todoCompletedClicked(incidenceData.incidencePtr)
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            }

            Kirigami.Action {
                icon.name: "list-add"
                text: i18n("Add Sub-Task")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onTriggered: {
                    const parentWrapper = Calendar.CalendarManager.createIncidenceWrapper()
                    parentWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);

                    Calendar.IncidenceEditorManager.openNewTodoEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, parentWrapper)
                }
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            }

            Kirigami.Action {
                id: setPriorityMenu
                text: i18n("Set priority…")
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo

                function setPriority(level) {
                    const wrapper = Calendar.CalendarManager.createIncidenceWrapper()
                    wrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);
                    wrapper.priority = level;
                    Calendar.CalendarManager.editIncidence(wrapper);
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("None")
                    onTriggered: setPriorityMenu.setPriority(0)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("1 (highest priority)")
                    onTriggered: setPriorityMenu.setPriority(1)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("2 (mid-high priority)")
                    onTriggered: setPriorityMenu.setPriority(2)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("3 (mid-high priority)")
                    onTriggered: setPriorityMenu.setPriority(3)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("4 (mid-high priority)")
                    onTriggered: setPriorityMenu.setPriority(4)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("5 (medium priority)")
                    onTriggered: setPriorityMenu.setPriority(5)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("6 (mid-low priority)")
                    onTriggered: setPriorityMenu.setPriority(6)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("7 (mid-low priority)")
                    onTriggered: setPriorityMenu.setPriority(7)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("8 (mid-low priority)")
                    onTriggered: setPriorityMenu.setPriority(8)
                }

                QQC2.Action {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("9 (lowest priority)")
                    onTriggered: setPriorityMenu.setPriority(9)
                }
            }

            Kirigami.Action {
                id: setDueDateMenu
                text: i18n("Set due date…")
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo

                function setDate(date) {
                    const wrapper = Calendar.CalendarManager.createIncidenceWrapper()
                    wrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);

                    if(date && !isNaN(date.getTime())) {
                        // Remember we have to convert from JS months (0-11) to Qt months (1-12)
                        wrapper.setIncidenceEndDate(date.getDate(), date.getMonth() + 1, date.getFullYear());
                        wrapper.allDay = true;
                    } else {
                        wrapper.incidenceEnd = new Date(undefined);
                    }

                    Calendar.CalendarManager.editIncidence(wrapper);
                }

                QQC2.Action {
                    icon.name: "edit-none"
                    text: i18n("None")
                    onTriggered: setDueDateMenu.setDate(undefined)
                }

                QQC2.Action {
                    readonly property date dateToday: new Date()

                    icon.name: "go-jump-today"
                    text: i18n("Today (%1)", dateToday.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onTriggered: setDueDateMenu.setDate(dateToday)
                }

                QQC2.Action {
                    readonly property date dateTomorrow: {
                        let date = new Date();
                        date.setDate(date.getDate() + 1);
                        return date;
                    }

                    icon.name: "view-calendar-day"
                    text: i18n("Tomorrow (%1)", dateTomorrow.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onTriggered: setDueDateMenu.setDate(dateTomorrow);
                }

                QQC2.Action {
                    readonly property date dateInAWeek: {
                        let date = new Date();
                        date.setDate(date.getDate() + 7);
                        return date;
                    }
                    icon.name: "view-calendar-week"
                    text: i18n("In a week (%1)", dateInAWeek.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onTriggered: setDueDateMenu.setDate(dateInAWeek);
                }

                QQC2.Action {
                    readonly property date dateInAMonth: {
                        let date = new Date();
                        date.setMonth(date.getMonth() + 1);
                        return date;
                    }

                    icon.name: "view-calendar-month"
                    text: i18n("In a month (%1)", dateInAMonth.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onTriggered: setDueDateMenu.setDate(dateInAMonth);
                }
            }
        }
    }
}
