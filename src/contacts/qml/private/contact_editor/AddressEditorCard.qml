// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCard {
    id: root
    objectName: "addressEditorCard"

    required property ContactEditor contactEditor
    signal addressRequested(int row)

    Component.onCompleted: autoSeparators = true

    Repeater {
        model: root.contactEditor?.contact.addressesModel

        delegate: FormCard.FormButtonDelegate {
            objectName: "addressRow" + index
            required property int index
            required property string formattedAddress
            required property string typeLabel
            required property string label

            text: typeLabel.length > 0 ? typeLabel : KI18n.i18nc("@item:inlistbox", "Address")
            description: formattedAddress.length > 0 ? formattedAddress : label
            trailingLogo.source: "document-edit-symbolic"
            trailingLogo.implicitWidth: Kirigami.Units.iconSizes.small
            trailingLogo.implicitHeight: Kirigami.Units.iconSizes.small
            onClicked: root.addressRequested(index)
        }
    }

    FormCard.FormButtonDelegate {
        objectName: "addAddressButton"
        text: KI18n.i18nc("@action:button", "Add address")
        icon.name: "list-add-symbolic"
        onClicked: root.addressRequested(-1)
    }
}
