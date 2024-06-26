// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components 1.0

QQC2.Menu {
    id: root

    required property var application

    title: i18nc("@action:menu", "Settings")

    KActionFromAction {
        action: root.application.action("toggle_menubar")
    }

    KActionFromAction {
        action: root.application.action("open_tag_manager")
    }

    QQC2.MenuSeparator {}

    KActionFromAction {
        action: root.application.action("options_configure_keybinding")
    }

    KActionFromAction {
        action: root.application.action("options_configure")
    }
}
