// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.kirigamiaddons.baseapp as BaseApp

QQC2.Menu {
    id: root

    required property var application

    title: i18nc("@action:menu", "Settings")

    BaseApp.Action {
        actionName: "toggle_menubar"
    }

    BaseApp.Action {
        actionName: "open_tag_manager"
    }

    QQC2.MenuSeparator {}

    BaseApp.Action {
        actionName: "options_configure_keybinding"
    }

    BaseApp.Action {
        actionName: "options_configure"
    }
}
