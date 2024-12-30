// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import Qt.labs.platform as Labs
import org.kde.merkuro.components

Labs.Menu {
    id: root

    title: i18nc("@action:menu", "File")

    default property list<QtObject> additionalMenuItems

    Labs.MenuItem {
        text: i18nc("@action:menu", "Quit Merkuro")
        icon.name: "application-exit"
        shortcut: StandardKey.Quit
        onTriggered: Qt.quit()
    }

    Component.onCompleted: {
        for (let menu of additionalMenuItems) {
            root.insertMenu(0, menu);
        }
    }
}
