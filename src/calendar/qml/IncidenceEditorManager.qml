// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2024 Carl Schwan <carlschwan@kde.org>
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma Singleton

import QtQml
import QtQuick
import QtQuick.Controls as Controls
import org.kde.merkuro.calendar as Calendar
import org.kde.kirigami as Kirigami
import org.kde.merkuro.components as BaseApplication

QtObject {
    id: root

    function getEditor(window) {
        if (Kirigami.Settings.isMobile) {
            const component = Qt.createComponent(Qt.resolvedUrl('./IncidenceEditorPage.qml'));
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return null;
            }

            return window.pageStack.layers.push(component);
        }

        const component = Qt.createComponent(Qt.resolvedUrl('./IncidenceEditorDialog.qml'));
        if (component.status === Component.Error) {
            console.error(component.errorString());
            return null;
        }
        return component.createObject(window).incidenceEditorPage;
    }

    function openEditorDialog(window, incidencePtr) {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        editor.incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
        editor.incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(incidencePtr);
        editor.incidenceWrapper.triggerEditMode();
        editor.editMode = true;
    }

    function openNewTodoEditorDialog(window: Kirigami.ApplicationWindow, parentWrapper: Calendar.IncidenceWrapper): void {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        editor.incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
        editor.editMode = false;
        editor.incidenceWrapper.setNewTodo();
        editor.incidenceWrapper.parent = parentWrapper.uid;
        editor.incidenceWrapper.collectionId = parentWrapper.collectionId;
        editor.incidenceWrapper.incidenceStart = parentWrapper.incidenceStart;
        editor.incidenceWrapper.incidenceEnd = parentWrapper.incidenceEnd;
    }

    function openNewIncidenceEditorDialog(window: Kirigami.ApplicationWindow, type: int, eventDate: date, collectionId: int, includeTime: bool): void {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        editor.incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
        editor.editMode = false;

        if(type === Calendar.IncidenceWrapper.TypeEvent) {
            editor.incidenceWrapper.setNewEvent();
        } else if (type === Calendar.IncidenceWrapper.TypeTodo) {
            editor.incidenceWrapper.setNewTodo();
        } else {
            console.error("Trying to open editor with an unsupported type", type);
            return;
        }

        if(eventDate !== undefined && !isNaN(eventDate.getTime())) {
            let existingStart = editor.incidenceWrapper.incidenceStart;
            let existingEnd = editor.incidenceWrapper.incidenceEnd;

            let newStart = eventDate;
            let newEnd = new Date(newStart.getFullYear(), newStart.getMonth(), newStart.getDate(), newStart.getHours() + 1, newStart.getMinutes());

            if(!includeTime) {
                newStart = new Date(eventDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                newEnd = new Date(eventDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
            }

            if(type === Calendar.IncidenceWrapper.TypeEvent) {
                editor.incidenceWrapper.incidenceStart = newStart;
                editor.incidenceWrapper.incidenceEnd = newEnd;
            } else if (type === Calendar.IncidenceWrapper.TypeTodo) {
                editor.incidenceWrapper.incidenceEnd = newStart;
            }
        }

        if(collectionId && collectionId >= 0) {
            editor.incidenceWrapper.collectionId = collectionId;
            return;
        }

        if(type === Calendar.IncidenceWrapper.TypeEvent && Calendar.Config.lastUsedEventCollection > -1) {
            editor.incidenceWrapper.collectionId = Calendar.Config.lastUsedEventCollection;
        } else if (type === Calendar.IncidenceWrapper.TypeTodo && Calendar.Config.lastUsedTodoCollection > -1) {
            editor.incidenceWrapper.collectionId = Calendar.Config.lastUsedTodoCollection;
        } else {
            editor.incidenceWrapper.collectionId = Calendar.CalendarManager.defaultCalendarId(editor.incidenceWrapper);
        }
    }
}
