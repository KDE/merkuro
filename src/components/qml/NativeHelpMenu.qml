// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform as Labs
import org.kde.kirigamiaddons.statefulapp.labs as StatefulAppLabs
import org.kde.kirigamiaddons.statefulapp as StatefulApp

Labs.Menu {
    id: root

    required property StatefulApp.AbstractKirigamiApplication application

    title: i18nc("@action:menu", "Help")

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_about_page"
        application: root.application
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_about_kde_page"
        application: root.application
    }

    Labs.MenuItem {
        text: i18nc("@action:menu", "Merkuro Handbook") // todo
        visible: false
    }
}
