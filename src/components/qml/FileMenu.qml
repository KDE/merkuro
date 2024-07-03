// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.kirigami as Kirigami

QQC2.Menu {
    id: fileMenu

    default property list<QtObject> additionalMenuItems

    title: i18nc("@action:menu", "File")

    property list<QtObject> _menuItems: [
        QQC2.MenuItem {
            action: QQC2.Action {
                text: i18nc("@action:menu", "Quit Merkuro")
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
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
