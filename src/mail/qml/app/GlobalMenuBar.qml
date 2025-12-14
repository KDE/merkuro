// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kirigamiaddons.statefulapp.labs as StatefulAppLabs

Labs.MenuBar {
    id: root

    required property StatefulApp.AbstractKirigamiApplication application

    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_month_view'
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_week_view'
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_threeday_view"
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_day_view"
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_schedule_view'
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_todo_view'
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_contact_view'
            application: root.application
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_kcommand_bar'
            application: root.application
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        StatefulAppLabs.NativeMenuItem {
            actionName: 'create_mail'
            application: root.application
        }
    }
    Labs.Menu {
        title: i18nc("@action:menu", "Window")

        Labs.MenuItem {
            text: root.window.visibility === Window.FullScreen ? i18nc("@action:menu", "Exit Full Screen") : i18nc("@action:menu", "Enter Full Screen")
            icon.name: "view-fullscreen"
            shortcut: "F11"
            onTriggered: root.window.visibility === Window.FullScreen ? root.window.showNormal() : root.window.showFullScreen()
        }
    }

    NativeHelpMenu {
        application: root.application
    }
}
