// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.merkuro.contact
import org.kde.kirigami as Kirigami

QQC2.MenuBar {
    FileMenu {}

    EditMenu {}

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        Kirigami.Action {
            fromQAction: ContactApplication.action('open_kcommand_bar')
        }

        Kirigami.Action {
            fromQAction: ContactApplication.action("refresh_all")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        Kirigami.Action {
            fromQAction: ContactApplication.action("create_contact")
        }

        Kirigami.Action {
            fromQAction: ContactApplication.action("create_contact_group")
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
