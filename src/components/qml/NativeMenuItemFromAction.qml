// SPDX-FileCopyrightText: 2020 (c) Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.7
import Qt.labs.platform
import org.kde.merkuro.components 1.0

MenuItem {
    required property var action

    text: action.text
    shortcut: action.shortcut
    icon.name: Helper.iconName(action.icon)
    onTriggered: action.trigger()
    visible: action.text.length > 0
    checkable: action.checkable
    checked: action.checked
    enabled: action.enabled && parent.enabled
}
