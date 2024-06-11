// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.baseapp as BaseApp

QQC2.MenuBar {
    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        BaseApp.Action {
            actionName: 'open_kcommand_bar'
        }

        BaseApp.Action {
            actionName: "refresh_all"
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        BaseApp.Action {
            actionName: "create_contact"
        }
        BaseApp.Action {
            actionName: "create_contact_group"
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
