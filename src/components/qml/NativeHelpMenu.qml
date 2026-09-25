// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform as Labs
import org.kde.kirigamiaddons.actions.labs as StatefulAppLabs
import org.kde.ki18n

Labs.Menu {
    id: root

    required property AbstractMerkuroApplication application

    title: KI18n.i18nc("@action:menu", "Help")

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_about_page"
        actionObject: root.application.action("open_about_page")
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_about_kde_page"
        actionObject: root.application.action("open_about_kde_page")
    }

    Labs.MenuItem {
        text: KI18n.i18nc("@action:menu", "Merkuro Handbook") // todo
        visible: false
    }
}
