// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor

    FormCard.FormTextFieldDelegate {
        id: partnerDelegate
        label: KI18n.i18nc("@label", "Partner's name")
        text: root.contactEditor.contact.spousesName
        onTextChanged: root.contactEditor.contact.spousesName = text
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormDateTimeDelegate {
        id: anniversaryDelegate
        text: KI18n.i18nc("@label", "Anniversary")
        dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
        value: root.contactEditor.contact.anniversary
        onValueChanged: root.contactEditor.contact.anniversary = value
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormDateTimeDelegate {
        id: birtdayDelegate
        text: KI18n.i18nc("@label", "Birthday")
        dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
        value: root.contactEditor.contact.birthday
        onValueChanged: root.contactEditor.contact.birthday = value
    }
}
