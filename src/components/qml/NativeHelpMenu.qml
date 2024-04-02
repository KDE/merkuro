// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform as Labs
import org.kde.merkuro.components 1.0

Labs.Menu {
    id: root

    required property var application

    title: i18nc("@action:menu", "Help")

    NativeMenuItemFromAction {
        action: root.application.action("open_about_page")
    }

    NativeMenuItemFromAction {
        action: root.application.action("open_about_kde_page")
    }

    Labs.MenuItem {
        text: i18nc("@action:menu", "Merkuro Handbook") // todo
        visible: false
    }
}
