// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.statefulapp.labs as StatefuleAppLabs

Labs.MenuBar {
    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "View")

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
        title: i18nc("@action:menu", "Create")

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

    Labs.Menu {
        title: i18nc("@action:menu", "Settings")

        StatefuleAppLabs.NativeMenuItem {
            actionName: 'open_tag_manager'
            application: ContactApplication
        }

        Labs.MenuSeparator {}

        StatefuleAppLabs.NativeMenuItem {
            actionName: 'options_configure_keybinding'
            application: ContactApplication
        }

        StatefuleAppLabs.NativeMenuItem {
            actionName: 'options_configure'
            application: ContactApplication
        }
    }

    NativeHelpMenu {
        application: ContactApplication
    }
}
