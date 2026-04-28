// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform as Labs
import org.kde.kirigamiaddons.statefulapp.labs as StatefulAppLabs
import org.kde.kirigamiaddons.statefulapp as StatefulApp

Labs.Menu {
    id: root

    required property StatefulApp.AbstractKirigamiApplication application

    title: i18nc("@action:menu", "Settings")

    StatefulAppLabs.NativeMenuItem {
        actionName: "toggle_menubar"
        application: root.application
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_tag_manager"
        application: root.application
    }

    Labs.MenuSeparator {}

    StatefulAppLabs.NativeMenuItem {
        actionName: "options_configure_keybinding"
        application: root.application
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "options_configure"
        application: root.application
    }
}
