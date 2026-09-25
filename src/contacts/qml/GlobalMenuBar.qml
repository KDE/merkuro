// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import Qt.labs.platform as Labs

import QtQuick
import org.kde.merkuro.components
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.actions.labs as StatefuleAppLabs
import org.kde.ki18n

Labs.MenuBar {
    NativeFileMenu {
        StatefuleAppLabs.NativeMenuItem {
            actionName: "import_contacts"
            actionObject: ContactApplication.action("import_contacts")
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "export_contacts"
            actionObject: ContactApplication.action("export_contacts")
        }
    }

    NativeEditMenu {}

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "View")

        StatefuleAppLabs.NativeMenuItem {
            actionName: 'open_kcommand_bar'
            actionObject: ContactApplication.action("open_kcommand_bar")
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "refresh_all"
            actionObject: ContactApplication.action("refresh_all")
        }
    }

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "Create")

        StatefuleAppLabs.NativeMenuItem {
            actionName: "create_contact"
            actionObject: ContactApplication.action("create_contact")
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "create_contact_group"
            actionObject: ContactApplication.action("create_contact_group")
        }
    }

    NativeWindowMenu {}

    NativeSettingsMenu {
        application: ContactApplication
    }

    NativeHelpMenu {
        application: ContactApplication
    }
}
