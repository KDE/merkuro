// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import Qt.labs.platform as Labs
import org.kde.merkuro.components 1.0

Labs.Menu {
    id: fileMenu
    title: i18nc("@action:menu", "File")

    default property list<QtObject> additionalMenuItems

    property list<QtObject> _menuItems: [
        Labs.MenuItem {
            text: i18nc("@action:menu", "Quit Merkuro")
            icon.name: "application-exit"
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    ]

    Component.onCompleted: {
        for (let i in additionalMenuItems) {
            fileMenu.addItem(additionalMenuItems[i])
        }
        for (let j in _menuItems) {
            fileMenu.addItem(_menuItems[j])
        }
    }
}
