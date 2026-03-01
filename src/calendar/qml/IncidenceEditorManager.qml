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
            const component = Qt.createComponent("org.kde.merkuro.calendar", "IncidenceEditorPage");
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return null;
            }

            const editor = window.pageStack.layers.push(component);
            editor.cancel.connect(() => editor.Window.window.pageStack.layers.pop());
            return editor;
        } else {
            const component = Qt.createComponent("org.kde.merkuro.calendar", "IncidenceEditorDialog");
            if (component.status === Component.Error) {
                console.error(component.errorString());
                return null;
            }
            return component.createObject(window).incidenceEditorPage;
        }
    }

    function openEditorDialog(window, incidencePtr) {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        let wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        wrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(incidencePtr);
        wrapper.triggerEditMode();
        Qt.callLater(function() {
            editor.incidenceWrapper = wrapper;
            editor.editMode = true;
        });
    }

    function openNewTodoEditorDialog(window: Kirigami.ApplicationWindow, parentWrapper: Calendar.IncidenceWrapper): void {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        let wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        wrapper.setNewTodo();
        wrapper.parent = parentWrapper.uid;
        wrapper.collectionId = parentWrapper.collectionId;
        wrapper.incidenceStart = parentWrapper.incidenceStart;
        wrapper.incidenceEnd = parentWrapper.incidenceEnd;
        Qt.callLater(function() {
            editor.incidenceWrapper = wrapper;
            editor.editMode = false;
        });
    }

    function openNewIncidenceEditorDialog(window: Kirigami.ApplicationWindow, type: int, eventDate: date, collectionId: int, includeTime: bool): void {
        const editor = getEditor(window);
        if (!editor) {
            return;
        }

        let wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        if(type === Calendar.IncidenceWrapper.TypeEvent) {
            wrapper.setNewEvent();
        } else if (type === Calendar.IncidenceWrapper.TypeTodo) {
            wrapper.setNewTodo();
        } else {
            console.error("Trying to open editor with an unsupported type", type);
            return;
        }

        if(eventDate !== undefined && !isNaN(eventDate.getTime())) {
            let existingStart = wrapper.incidenceStart;
            let existingEnd = wrapper.incidenceEnd;

            let newStart = eventDate;
            let newEnd = new Date(newStart.getFullYear(), newStart.getMonth(), newStart.getDate(), newStart.getHours() + 1, newStart.getMinutes());

            if(!includeTime) {
                if (!isNaN(existingStart.getTime())) {
                    newStart = new Date(eventDate.setHours(existingStart.getHours(), existingStart.getMinutes()));
                    newEnd = new Date(eventDate.setHours(existingStart.getHours() + 1, existingStart.getMinutes()));
                }
            }

            if(type === Calendar.IncidenceWrapper.TypeEvent) {
                wrapper.incidenceStart = newStart;
                wrapper.incidenceEnd = newEnd;
            } else if (type === Calendar.IncidenceWrapper.TypeTodo) {
                wrapper.incidenceEnd = newStart;
            }
        }

        if(collectionId && collectionId >= 0) {
            wrapper.collectionId = collectionId;
        } else if(type === Calendar.IncidenceWrapper.TypeEvent && Calendar.Config.lastUsedEventCollection > -1) {
            wrapper.collectionId = Calendar.Config.lastUsedEventCollection;
        } else if (type === Calendar.IncidenceWrapper.TypeTodo && Calendar.Config.lastUsedTodoCollection > -1) {
            wrapper.collectionId = Calendar.Config.lastUsedTodoCollection;
        } else {
            wrapper.collectionId = Calendar.CalendarManager.defaultCalendarId(wrapper);
        }

        Qt.callLater(function() {
            editor.incidenceWrapper = wrapper;
            editor.editMode = false;
        });
    }
}
