// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components 1.0
import org.kde.merkuro.contact 1.0

QQC2.MenuBar {
    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            action: ContactApplication.action('open_kcommand_bar')
        }

        KActionFromAction {
            action: ContactApplication.action("refresh_all")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            action: ContactApplication.action("create_contact")
        }
        KActionFromAction {
            action: ContactApplication.action("create_contact_group")
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: ContactApplication
    }

    HelpMenu {
        application: ContactApplication
    }
}
