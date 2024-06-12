// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.kirigamiaddons.statefulapp as StatefulApp

QQC2.Menu {
    id: root

    required property var application

    title: i18nc("@action:menu", "Settings")

    StatefulApp.Action {
        actionName: "toggle_menubar"
    }

    StatefulApp.Action {
        actionName: "open_tag_manager"
    }

    QQC2.MenuSeparator {}

    StatefulApp.Action {
        actionName: "options_configure_keybinding"
    }

    StatefulApp.Action {
        actionName: "options_configure"
    }
}
