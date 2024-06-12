// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.merkuro.mail
import org.kde.kirigamiaddons.statefulapp as StatefulApp

QQC2.MenuBar {
    id: bar

    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        StatefulApp.Action {
            actionName: 'open_kcommand_bar'
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        StatefulApp.Action {
            actionName: "create_mail"
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: MailApplication
    }

    HelpMenu {
        application: MailApplication
    }
}
