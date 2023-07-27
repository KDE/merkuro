// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0

MobileForm.FormCard {
    id: root

    readonly property IdentityModel _identityModel: IdentityModel {}

    contentItem: ColumnLayout {
        spacing: 0

        MobileForm.FormCardHeader {
            title: i18n("Identities")
        }

        Repeater {
            model: root._identityModel
            delegate: MobileForm.FormButtonDelegate {
                leadingPadding: Kirigami.Units.largeSpacing
                text: model.display
            }
        }
    }
}
