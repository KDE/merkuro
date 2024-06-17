// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components

QQC2.Menu {
    id: root

    required property AbstractMerkuroApplication application

    StatefulApp.Action {
        application: root.application
        merkuroAction: "open_contact_view"
    }
    StatefulApp.Action {
        application: root.application
        merkuroAction: "open_mail_view"
    }
    StatefulApp.Action {
        application: root.application
        merkuroAction: 'open_kcommand_bar'
    }
}
