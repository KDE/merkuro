// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import QtQuick.Window
import org.kde.merkuro.components 1.0
import org.kde.merkuro.contact 1.0

Labs.MenuBar {
    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        NativeMenuItemFromAction {
            action: ContactApplication.action('open_kcommand_bar')
        }

        NativeMenuItemFromAction {
            action: ContactApplication.action("refresh_all")
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            action: ContactApplication.action("create_contact")
        }
        NativeMenuItemFromAction {
            action: ContactApplication.action("create_contact_group")
        }
    }

    NativeWindowMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "Settings")

        NativeMenuItemFromAction {
            action: ContactApplication.action('open_tag_manager')
        }

        Labs.MenuSeparator {}

        NativeMenuItemFromAction {
            action: ContactApplication.action('options_configure_keybinding')
        }
        NativeMenuItemFromAction {
            action: ContactApplication.action('options_configure')
        }
    }

    NativeHelpMenu {
        application: ContactApplication
    }
}
