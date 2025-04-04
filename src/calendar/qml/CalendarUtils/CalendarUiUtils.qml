// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar
import org.kde.merkuro.contact

QtObject {
    id: utilsObject
    property var appMain

    readonly property bool darkMode: LabelUtils.isDarkColor(Kirigami.Theme.backgroundColor)

    function setUpView(modelData, incidenceItem = null) {
        // Choose between opening the incidence information in the drawer or the popup
        const usingDrawer = Kirigami.Settings.isMobile ||
                            !incidenceItem ||
                            !Config.useIncidenceInfoPopup;

        appMain.incidenceInfoDrawerEnabled = usingDrawer;
        appMain.incidenceInfoPopupEnabled = !usingDrawer;

        const incidenceInfoComponent = usingDrawer ? appMain.incidenceInfoDrawer : appMain.incidenceInfoPopup;

        // HACK: Give it a chance to reset properly
        incidenceInfoComponent.incidenceData = null;
        incidenceInfoComponent.incidenceData = modelData;

        if (!usingDrawer) {
            incidenceInfoComponent.openingIncidenceItem = incidenceItem;
        }

        incidenceInfoComponent.open();
    }

    function fakeModelDataFromIncidenceWrapper(incidenceWrapper) {
        // Spoof what a modelData would look like from the model
        const collectionDetails = CalendarManager.getCollectionDetails(incidenceWrapper.collectionId)
        const fakeModelData = {
            "text": incidenceWrapper.summary,
            "description": incidenceWrapper.description,
            "location": incidenceWrapper.location,
            "startTime": incidenceWrapper.incidenceStart,
            "endTime": incidenceWrapper.incidenceEnd,
            "allDay": incidenceWrapper.allDay,
            "todoCompleted": incidenceWrapper.todoCompleted,
            "priority": incidenceWrapper.priority,
            // These next two are mainly used in the hourly and day grid views, and we don't use this for
            // anything but the incidence info drawer -- for now. Remember that they are different to
            // the incidence's actual startTime and duration time -- these are just for positioning!
            //"starts":
            //"duration":
            "durationString": incidenceWrapper.durationDisplayString,
            "recurs": incidenceWrapper.recurrenceData.type !== 0,
            "hasReminders": incidenceWrapper.hasReminders(),
            "isOverdue": incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo &&
                         !isNaN(incidenceWrapper.incidenceEnd.getTime()) &&
                         incidenceWrapper.incidenceEnd < appMain.currentDate,
            "isReadOnly": collectionDetails.readOnly,
            "color": collectionDetails.color,
            "collectionId": incidenceWrapper.collectionId,
            "incidenceId": incidenceWrapper.uid,
            "incidenceType": incidenceWrapper.incidenceType,
            "incidenceTypeStr": incidenceWrapper.incidenceTypeStr,
            "incidenceTypeIcon": incidenceWrapper.incidenceIconName,
            "incidencePtr": incidenceWrapper.incidencePtr,
            //"incidenceOccurrence":
        };

        return fakeModelData;
    }

    function setUpEdit(incidencePtr) {
        let editorToUse = utilsObject.editorToUse();
        editorToUse.incidenceWrapper = CalendarManager.createIncidenceWrapper();
        editorToUse.incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);
        editorToUse.incidenceWrapper.triggerEditMode();
        editorToUse.editMode = true;
    }

    function setUpDelete(incidencePtr, deleteDate) {
        let incidenceWrapper = CalendarManager.createIncidenceWrapper();
        incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        const dialog = appMain.deleteIncidenceDialogComponent.createObject(appMain.contentItem, {
            incidenceWrapper: incidenceWrapper,
            deleteDate: deleteDate
        });

        dialog.open();
    }

    function completeTodo(incidencePtr) {
        let todo = CalendarManager.createIncidenceWrapper();
        todo.incidenceItem = CalendarManager.incidenceItem(incidencePtr);

        if(todo.incidenceType === IncidenceWrapper.TypeTodo) {
            todo.todoCompleted = !todo.todoCompleted;
            CalendarManager.editIncidence(todo);
        }
    }

    function setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, occurrenceDate, caughtDelegate, allDay=null) {
        appMain.pageStack.currentItem.dragDropEnabled = false;

        if(appMain.pageStack.layers.currentItem && appMain.pageStack.layers.currentItem.dragDropEnabled) {
            appMain.pageStack.layers.currentItem.dragDropEnabled = false;
        }

        if(incidenceWrapper.recurrenceData.type === 0) {
            if (allDay !== null) {
                incidenceWrapper.allDay = allDay;
            }
            CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset);
        } else {
            const onClosingHandler = () => { caughtDelegate.caught = false; utilsObject.reenableDragOnCurrentView(); };
            const openDialogWindow = appMain.pageStack.pushDialogLayer(appMain.recurringIncidenceChangePageComponent, {
                incidenceWrapper: incidenceWrapper,
                startOffset: startOffset,
                endOffset: endOffset,
                occurrenceDate: occurrenceDate,
                caughtDelegate: caughtDelegate,
                allDay: allDay
            }, {
                width: Kirigami.Units.gridUnit * 34,
                height: Kirigami.Units.gridUnit * 6,
                onClosing: onClosingHandler()
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }

    function reenableDragOnCurrentView() {
        appMain.pageStack.currentItem.dragDropEnabled = true;

        if(appMain.pageStack.layers.currentItem && appMain.pageStack.layers.currentItem.dragDropEnabled) {
            appMain.pageStack.layers.currentItem.dragDropEnabled = true;
        }
    }

    function openDayLayer(selectedDate) {
        if(!isNaN(selectedDate.getTime())) {
            DateTimeState.setSelectedYearMonthDay(selectedDate.getFullYear(), selectedDate.getMonth() + 1, selectedDate.getDate());
            appMain.dayViewAction.trigger();
        }
    }
}
