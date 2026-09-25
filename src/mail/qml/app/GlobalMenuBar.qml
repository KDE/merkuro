// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.merkuro.components
import org.kde.kirigamiaddons.actions.labs as StatefulAppLabs
import org.kde.ki18n

Labs.MenuBar {
    id: root

    required property AbstractMerkuroApplication application

    NativeFileMenu {}

    NativeEditMenu {}

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "View")

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_kcommand_bar'
            actionObject: root.application.action("open_kcommand_bar")
        }
    }

    Labs.Menu {
        title: KI18n.i18nc("@action:menu", "Create")

        StatefulAppLabs.NativeMenuItem {
            actionName: 'create_mail'
            actionObject: root.application.action("create_mail")
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
