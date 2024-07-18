// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.kirigami as Kirigami

QQC2.Menu {
    id: root

    required property AbstractMerkuroApplication application

    title: i18nc("@action:menu", "Settings")

    Kirigami.Action {
        fromQAction: root.application.action("toggle_menubar")
    }

    Kirigami.Action {
        fromQAction: root.application.action("open_tag_manager")
    }

    QQC2.MenuSeparator {}

    Kirigami.Action {
        fromQAction: root.application.action("options_configure_keybinding")
    }

    Kirigami.Action {
        fromQAction: root.application.action("options_configure")
    }
}
