// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform as Labs
import org.kde.kirigamiaddons.actions.labs as StatefulAppLabs
import org.kde.ki18n

Labs.Menu {
    id: root

    required property AbstractMerkuroApplication application

    title: KI18n.i18nc("@action:menu", "Settings")

    StatefulAppLabs.NativeMenuItem {
        actionName: "toggle_menubar"
        actionObject: root.application.action("toggle_menubar")
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "open_tag_manager"
        actionObject: root.application.action("open_tag_manager")
    }

    Labs.MenuSeparator {}

    StatefulAppLabs.NativeMenuItem {
        actionName: "options_configure_keybinding"
        actionObject: root.application.action("options_configure_keybinding")
    }

    StatefulAppLabs.NativeMenuItem {
        actionName: "options_configure"
        actionObject: root.application.action("options_configure")
    }
}
