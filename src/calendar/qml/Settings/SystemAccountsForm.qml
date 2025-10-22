// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import org.kde.akonadi
import org.kde.merkuro.calendar

FormCard.FormCard {
    id: root

    AccountsModel {
        id: accountsModel
    }

    Repeater {
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

            // onClicked: {
            //     dialog.agentDelegate = agentDelegate;
            //     dialog.open();
            // }
        }
    }

    FormCard.FormDelegateSeparator { below: addAccountDelegate }

    FormCard.FormButtonDelegate {
        id: addAccountDelegate
        text: i18ndc("libakonadi6", "@action:button", "Add Account")
        icon.name: "list-add-symbolic"
        onClicked: accountsModel.requestNew()
    }
}
