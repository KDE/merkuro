// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform 1.1 as Labs

import QtQuick 2.15
import QtQuick.Window 2.15
import org.kde.merkuro 1.0
import org.kde.merkuro.components 1.0

Labs.MenuBar {
    id: bar

    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        NativeMenuItemFromAction {
            merkuroAction: 'open_month_view'
        }

        NativeMenuItemFromAction {
            merkuroAction: 'open_week_view'
        }

        NativeMenuItemFromAction {
            merkuroAction: "open_threeday_view"
        }

        NativeMenuItemFromAction {
            merkuroAction: "open_day_view"
        }

        NativeMenuItemFromAction {
            merkuroAction: 'open_schedule_view'
        }

        NativeMenuItemFromAction {
            merkuroAction: 'open_todo_view'
        }

        NativeMenuItemFromAction {
            merkuroAction: 'open_contact_view'
        }

        NativeMenuItemFromAction {
            merkuroAction: 'open_kcommand_bar'
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        NativeMenuItemFromAction {
            merkuroAction: 'create_mail'
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Window")

        Labs.MenuItem {
            text: root.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
            icon.name: "view-fullscreen"
            shortcut: "F11"
            onTriggered: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen()
        }
    }

    NativeSettingsMenu {}

    NativeHelpMenu {}
}
