// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import Qt.labs.platform as Labs
import QtQuick
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.ki18n

Labs.Menu {
    id: editMenu
    title: KI18n.i18nc("@action:menu", "Edit")

    property Window _window: applicationWindow()

    property Connections _textInputConnection: Connections {
        target: _window
        function onActiveFocusItemChanged() {
            if (_window.activeFocusItem instanceof TextEdit || _window.activeFocusItem instanceof TextInput) {
                editMenu.field = _window.activeFocusItem;
            }
        }
    }

    property Item field: null

    Component.onCompleted: {
        for (let menu of additionalMenuItems) {
            editMenu.insertItem(0, menu)
        }
    }

    default property list<QtObject> additionalMenuItems

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canUndo
        text: KI18n.i18nc("text editing menu action", "Undo")
        shortcut: StandardKey.Undo
        onTriggered: {
            editMenu.field.undo()
            editMenu.close()
        }
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canRedo
        text: KI18n.i18nc("text editing menu action", "Redo")
        shortcut: StandardKey.Redo
        onTriggered: {
            editMenu.field.undo()
            editMenu.close()
        }
    }

    Labs.MenuSeparator {
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText
        text: KI18n.i18nc("text editing menu action", "Cut")
        shortcut: StandardKey.Cut
        onTriggered: {
            editMenu.field.cut()
            editMenu.close()
        }
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText
        text: KI18n.i18nc("text editing menu action", "Copy")
        shortcut: StandardKey.Copy
        onTriggered: {
            editMenu.field.copy()
            editMenu.close()
        }
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.canPaste
        text: KI18n.i18nc("text editing menu action", "Paste")
        shortcut: StandardKey.Paste
        onTriggered: {
            editMenu.field.paste()
            editMenu.close()
        }
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null && editMenu.field.selectedText !== ""
        text: KI18n.i18nc("text editing menu action", "Delete")
        shortcut: ""
        onTriggered: {
            editMenu.field.remove(editMenu.field.selectionStart, editMenu.field.selectionEnd)
            editMenu.close()
        }
    }

    Labs.MenuSeparator {
    }

    Labs.MenuItem {
        enabled: editMenu.field !== null
        text: KI18n.i18nc("text editing menu action", "Select All")
        shortcut: StandardKey.SelectAll
        onTriggered: {
            editMenu.field.selectAll()
            editMenu.close()
        }
    }
}
