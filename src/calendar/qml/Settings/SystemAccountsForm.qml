// SPDX-FileCopyrightText: 2025 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.merkuro.components

FormCard.FormCard {
    id: root

    required property list<string> types

    property alias available: accountsModel.onlineAccountsAvailable

    AccountsModel {
        id: accountsModel

        types: root.types
    }

    Repeater {
        id: accountsRepeater
        model: accountsModel
        delegate: FormCard.FormButtonDelegate {
            id: agentDelegate

            required property int index
            required property string iconName
            required property string name

            leadingPadding: Kirigami.Units.largeSpacing
            leading: Kirigami.Icon {
                source: agentDelegate.iconName
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
            }

            text: name
        }
    }

    FormCard.FormDelegateSeparator {
        below: addAccountDelegate
        visible: accountsRepeater.count > 0
    }

    FormCard.FormButtonDelegate {
        id: addAccountDelegate
        text: i18nc("@action:button", "Add Account…")
        icon.name: "list-add-symbolic"
        onClicked: accountsModel.requestNew()
    }
}
