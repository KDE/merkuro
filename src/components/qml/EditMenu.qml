// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Templates as T
import QtQuick.Window
import org.kde.ki18n

QQC2.Menu {
    id: editMenu

    property Window _window: applicationWindow()

    title: KI18n.i18nc("@action:menu", "Edit")

    property Connections _textInputConnection: Connections {
        target: editMenu._window
        function onActiveFocusItemChanged() {
            if (editMenu._window.activeFocusItem instanceof TextEdit || editMenu._window.activeFocusItem instanceof TextInput) {
                editMenu.field = editMenu._window.activeFocusItem;
            }
        }
    }
    property Item field: null

    Component.onCompleted: {
        for (let menuItem of additionalMenuItems) {
            if (menuItem instanceof T.Action) {
                editMenu.addAction(menuItem)
            } else {
                editMenu.addItem(menuItem)
            }
        }
        for (let j in _menuItems) {
            editMenu.addItem(_menuItems[j])
        }
    }

    default property list<QtObject> additionalMenuItems

    property list<QtObject> _menuItems: [
        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canUndo
            text: KI18n.i18nc("text editing menu action", "Undo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canRedo
            text: KI18n.i18nc("text editing menu action", "Redo Text")
            onTriggered: {
                editMenu.field.undo()
                editMenu.close()
            }
        },

        QQC2.MenuSeparator {
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: KI18n.i18nc("text editing menu action", "Cut")
            onTriggered: {
                editMenu.field.cut()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText
            text: KI18n.i18nc("text editing menu action", "Copy")
            onTriggered: {
                editMenu.field.copy()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.canPaste
            text: KI18n.i18nc("text editing menu action", "Paste")
            onTriggered: {
                editMenu.field.paste()
                editMenu.close()
            }
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
            text: KI18n.i18nc("text editing menu action", "Delete")
            onTriggered: {
                editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
                editMenu.close()
            }
        },

        QQC2.MenuSeparator {
        },

        QQC2.MenuItem {
            enabled: editMenu.field !== null
            text: KI18n.i18nc("text editing menu action", "Select All")
            onTriggered: {
                editMenu.field.selectAll()
                editMenu.close()
            }
        }
    ]
}
