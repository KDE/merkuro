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

    NativeWindowMenu {}

    NativeSettingsMenu {
        application: root.application
    }

    NativeHelpMenu {
        application: root.application
    }
}
