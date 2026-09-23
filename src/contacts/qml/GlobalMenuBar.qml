// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.statefulapp.labs as StatefuleAppLabs
import org.kde.ki18n

Labs.MenuBar {
    NativeFileMenu {
        StatefuleAppLabs.NativeMenuItem {
            actionName: "import_contacts"
            application: ContactApplication
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "export_contacts"
            application: ContactApplication
        }
    }

    NativeEditMenu {}

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "View")

        StatefuleAppLabs.NativeMenuItem {
            actionName: 'open_kcommand_bar'
            application: ContactApplication
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "refresh_all"
            application: ContactApplication
        }
    }

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "Create")

        StatefuleAppLabs.NativeMenuItem {
            actionName: "create_contact"
            application: ContactApplication
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: "create_contact_group"
            application: ContactApplication
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
