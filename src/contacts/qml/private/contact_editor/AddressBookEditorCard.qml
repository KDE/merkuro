// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import org.kde.ki18n

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor
    required property int mode
    required property double initialCollectionId

    property alias addressBookComboBoxId: addressBookComboBox.defaultCollectionId;
    property alias addressBookComboBox: addressBookComboBox

    Layout.topMargin: Kirigami.Units.largeSpacing

    Akonadi.FormCollectionComboBox {
        id: addressBookComboBox
        objectName: "addressBookComboBox"

        text: KI18n.i18n("Address book:")

        defaultCollectionId: if (root.mode === ContactEditor.CreateMode) {
            return root.initialCollectionId >= 0 ? root.initialCollectionId : ContactConfig.lastUsedAddressBookCollection;
        } else {
            return root.contactEditor.collectionId;
        }

        mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
        accessRightsFilter: Akonadi.Collection.CanCreateItem
        onUserSelectedCollection: collection => root.contactEditor.setDefaultAddressBook(collection)
    }

    FormCard.FormDelegateSeparator { above: addressBookComboBox; below: nameDelegate }

    FormCard.AbstractFormDelegate {
        id: nameDelegate

        contentItem: ColumnLayout {
		    spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: KI18n.i18n("Name")
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Layout.fillWidth: true

                QQC2.TextField {
                    id: textField
                    text: root.contactEditor.contact.formattedName
                    onTextEdited: root.contactEditor.contact.formattedName = text
                    placeholderText: KI18n.i18n("Contact name")

                    Accessible.description: KI18n.i18n("Name")
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    icon.name: 'settings-configure'
                    onClicked: displayAdvancedNameFields = !displayAdvancedNameFields

                    QQC2.ToolTip.text: KI18n.i18n("Advanced")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }

    ColumnLayout {
        visible: displayAdvancedNameFields

        FormCard.FormDelegateSeparator {}

        FormCard.FormComboBoxDelegate {
            text: KI18n.i18n("Honorific prefix")

            editable: true
            model: [KI18n.i18n("Dr."), KI18n.i18n("Miss"), KI18n.i18n("Mr."), KI18n.i18n("Mrs."), KI18n.i18n("Ms."), KI18n.i18n("Prof.")]
            currentIndex: -1
            editText: root.contactEditor.contact.prefix
            onCurrentValueChanged: root.contactEditor.contact.prefix = currentValue
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            label: KI18n.i18n("Given name")
            onTextChanged: root.contactEditor.contact.givenName = text
            text: root.contactEditor.contact.givenName
            placeholderText: KI18n.i18n("First name or chosen name")
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            label: KI18n.i18n("Additional name")
            onTextChanged: root.contactEditor.contact.additionalName = text
            text: root.contactEditor.contact.additionalName
            placeholderText: KI18n.i18n("Middle name or other name")
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            label: KI18n.i18n("Family name:")
            onTextChanged: root.contactEditor.contact.familyName = text
            text: root.contactEditor.contact.familyName
            placeholderText: KI18n.i18n("Surname or last name")
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormComboBoxDelegate {
            text: KI18n.i18n("Honorific suffix")
            onCurrentValueChanged: root.contactEditor.contact.suffix = currentValue
            editable: true
            editText: root.contactEditor.contact.suffix
            model: [KI18n.i18n("I"), KI18n.i18n("II"), KI18n.i18n("III"), KI18n.i18n("Jr."), KI18n.i18n("Sr.")]
            currentIndex: -1
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            label: KI18n.i18n("Nickname")
            onTextChanged: root.contactEditor.contact.nickName = text
            text: root.contactEditor.contact.nickName
            placeholderText: KI18n.i18n("Alternative name")
        }
    }

    FormCard.FormDelegateSeparator {}

    FormCard.FormTextFieldDelegate {
        id: blogFeedUrl
        label: KI18n.i18n("Blog Feed")
        text: root.contactEditor.contact.blogFeed
        onTextChanged: root.contactEditor.contact.blogFeed = text
        placeholderText: KI18n.i18n("https://planet.kde.org/")
    }
}
