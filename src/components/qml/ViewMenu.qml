// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components 1.0

QQC2.Menu {
    StatefulApp.Action {
        merkuroAction: "open_contact_view"
    }
    StatefulApp.Action {
        merkuroAction: "open_mail_view"
    }
    StatefulApp.Action {
        merkuroAction: 'open_kcommand_bar'
    }
}
