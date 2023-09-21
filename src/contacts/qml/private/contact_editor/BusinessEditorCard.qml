// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1
import Qt5Compat.GraphicalEffects

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import org.kde.merkuro.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor

    FormCard.FormTextFieldDelegate {
        id: organizationId
        label: i18n("Organization")
        text: root.contactEditor.contact.organization
        onTextChanged: root.contactEditor.contact.organization = text
        placeholderText: i18nc("Placeholder value for name of Organization", "KDE")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: professionId
        label: i18n("Profession")
        text: root.contactEditor.contact.profession
        onTextChanged: root.contactEditor.contact.profession = text
        placeholderText: i18nc("Placeholder value for name of Profession", "Software Developer")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: titleId
        label: i18n("Title")
        text: root.contactEditor.contact.title
        onTextChanged: root.contactEditor.contact.title = text
        placeholderText: i18nc("Placeholder value for Title", "SDE-1")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: deptId
        label: i18n("Department")
        text: root.contactEditor.contact.department
        onTextChanged: root.contactEditor.contact.department = text
        placeholderText: i18nc("Placeholder value for name of Department", "Merkuro-Team")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: officeId
        label: i18n("Office")
        text: root.contactEditor.contact.office
        onTextChanged: root.contactEditor.contact.office = text
        placeholderText: i18nc("Placeholder value for Office", "Tech Wing, 4th Floor")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: managersNameId
        label: i18n("Manager's Name")
        text: root.contactEditor.contact.managersName
        onTextChanged: root.contactEditor.contact.managersName = text
        placeholderText: i18nc("Placeholder value for Manager's Name", "Bob")
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: assistantsNameId
        label: i18n("Assistant's Name")
        text: root.contactEditor.contact.assistantsName
        onTextChanged: root.contactEditor.contact.assistantsName = text
        placeholderText: i18nc("Placeholder value for Assistants's Name", "Jill")
    }
}
