// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.utils

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
            incidenceActions.createObject(mouseArea, {}).open();
        }
    }
    onPressAndHold: if(Kirigami.Settings.isMobile) {
        clickX = mouseX;
        clickY = mouseY;
        incidenceActions.createObject(mouseArea, {}).open();
    }
    onDoubleClicked: {
        collectionDetails = Calendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)
        IncidenceEditorManager.openEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, incidenceData.incidencePtr)
    }

    Component {
        id: incidenceActions
        QQC2.Menu {
            id: actionsPopup
            y: mouseArea.clickY
            x: mouseArea.clickX
            z: 1000
            Component.onCompleted: if(mouseArea.collectionId && !mouseArea.collectionDetails) mouseArea.collectionDetails = Calendar.CalendarManager.getCollectionDetails(mouseArea.collectionId)

            QQC2.MenuItem {
                icon.name: "dialog-icon-preview"
                text: i18n("View")
                onClicked: viewClicked(incidenceData);
            }
            QQC2.MenuItem {
                icon.name: "edit-entry"
                text: i18n("Edit")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: () => {
                    IncidenceEditorManager.openEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, incidenceData.incidencePtr)
                }

            }
            QQC2.MenuItem {
                icon.name: "edit-delete"
                text:i18n("Delete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: deleteClicked(incidenceData.incidencePtr, incidenceData.startTime)
            }

            QQC2.MenuSeparator {
            }
            QQC2.MenuItem {
                icon.name: "task-complete"
                text: incidenceData.todoCompleted ? i18n("Mark Task as Incomplete") : i18n("Mark Task as Complete")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: todoCompletedClicked(incidenceData.incidencePtr)
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            }
            QQC2.MenuItem {
                icon.name: "list-add"
                text: i18n("Add Sub-Task")
                enabled: !mouseArea.collectionDetails["readOnly"]
                onClicked: {
                    const parentWrapper = Calendar.CalendarManager.createIncidenceWrapper()
                    parentWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);

                    IncidenceEditorManager.openNewTodoEditorDialog(QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow, parentWrapper)
                }
                visible: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            }
            QQC2.Menu {
                id: setPriorityMenu
                title: i18n("Set priority...")
                enabled: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
                z: 1001

                function setPriority(level) {
                    const wrapper = Calendar.CalendarManager.createIncidenceWrapper()
                    wrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(mouseArea.incidenceData.incidencePtr);
                    wrapper.priority = level;
                    Calendar.CalendarManager.editIncidence(wrapper);
                }

                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("None")
                    onClicked: setPriorityMenu.setPriority(0)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("1 (highest priority)")
                    onClicked: setPriorityMenu.setPriority(1)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("2 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(2)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("3 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(3)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("4 (mid-high priority)")
                    onClicked: setPriorityMenu.setPriority(4)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("5 (medium priority)")
                    onClicked: setPriorityMenu.setPriority(5)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("6 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(6)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("7 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(7)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("8 (mid-low priority)")
                    onClicked: setPriorityMenu.setPriority(8)
                }
                QQC2.MenuItem {
                    icon.name: "emblem-important-symbolic"
                    text: i18n("9 (lowest priority)")
                    onClicked: setPriorityMenu.setPriority(9)
                }
            }
            QQC2.Menu {
                id: setDueDateMenu
                title: i18n("Set due date...")
                enabled: incidenceData.incidenceType === Calendar.IncidenceWrapper.TypeTodo
                z: 1001

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

                QQC2.MenuItem {
                    icon.name: "edit-none"
                    text: i18n("None")
                    onClicked: setDueDateMenu.setDate(undefined)
                }
                QQC2.MenuItem {
                    readonly property date dateToday: new Date()

                    icon.name: "go-jump-today"
                    text: i18n("Today (%1)", dateToday.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onClicked: setDueDateMenu.setDate(dateToday)
                }
                QQC2.MenuItem {
                    readonly property date dateTomorrow: {
                        let date = new Date();
                        date.setDate(date.getDate() + 1);
                        return date;
                    }

                    icon.name: "view-calendar-day"
                    text: i18n("Tomorrow (%1)", dateTomorrow.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onClicked: setDueDateMenu.setDate(dateTomorrow);
                }
                QQC2.MenuItem {
                    readonly property date dateInAWeek: {
                        let date = new Date();
                        date.setDate(date.getDate() + 7);
                        return date;
                    }
                    icon.name: "view-calendar-week"
                    text: i18n("In a week (%1)", dateInAWeek.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onClicked: setDueDateMenu.setDate(dateInAWeek);
                }
                QQC2.MenuItem {
                    readonly property date dateInAMonth: {
                        let date = new Date();
                        date.setMonth(date.getMonth() + 1);
                        return date;
                    }

                    icon.name: "view-calendar-month"
                    text: i18n("In a month (%1)", dateInAMonth.toLocaleDateString(Qt.locale(), Locale.NarrowFormat))
                    onClicked: setDueDateMenu.setDate(dateInAMonth);
                }
            }
        }
    }
}
