// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCardPage {
    id: root
    objectName: "addressEditorPage"

    required property AddressModel addressModel
    property int row: -1
    readonly property var originalAddress: addressModel?.addressAt(row)
    property int selectedType: row < 0 ? AddressModel.Home : (originalAddress?.type ?? AddressModel.Other)
    readonly property var typeOptions: [
        { text: KI18n.i18nc("@item:inlistbox Address type", "Domestic"), value: AddressModel.Domestic },
        { text: KI18n.i18nc("@item:inlistbox Address type", "International"), value: AddressModel.International },
        { text: KI18n.i18nc("@item:inlistbox Address type", "Postal"), value: AddressModel.Postal },
        { text: KI18n.i18nc("@item:inlistbox Address type", "Parcel"), value: AddressModel.Parcel },
        { text: KI18n.i18nc("@item:inlistbox Address type", "Home"), value: AddressModel.Home },
        { text: KI18n.i18nc("@item:inlistbox Address type", "Work"), value: AddressModel.Work },
        { text: KI18n.i18nc("@item:inlistbox Address type", "Preferred"), value: AddressModel.Preferred },
    ]
    readonly property bool hasAddressDetails: (originalAddress?.geo.isValid ?? false)
        || postOfficeBoxField.text.trim().length > 0
        || extendedField.text.trim().length > 0
        || streetField.text.trim().length > 0
        || cityField.text.trim().length > 0
        || regionField.text.trim().length > 0
        || postalCodeField.text.trim().length > 0
        || countryField.text.trim().length > 0
        || labelField.text.trim().length > 0

    title: row < 0 ? KI18n.i18nc("@title:window", "Add address") : KI18n.i18nc("@title:window", "Edit address")

    function saveAddress(): void {
        let address = addressModel.addressAt(row);
        address.type = selectedType;
        address.postOfficeBox = postOfficeBoxField.text;
        address.extended = extendedField.text;
        address.street = streetField.text;
        address.locality = cityField.text;
        address.region = regionField.text;
        address.postalCode = postalCodeField.text;
        address.country = countryField.text;
        address.label = labelField.text;
        if (row < 0) {
            addressModel.addAddress(address);
        } else {
            addressModel.updateAddress(row, address);
        }
    }

    FormCard.FormCard {
        Layout.topMargin: Kirigami.Units.largeSpacing

        FormCard.FormComboBoxDelegate {
            id: addressTypeCombo
            objectName: "addressTypeCombo"
            text: KI18n.i18nc("@label:listbox", "Address type")
            model: root.typeOptions.findIndex(option => option.value === root.selectedType) < 0
                ? [...root.typeOptions, { text: KI18n.i18nc("@item:inlistbox Address type", "Other"), value: root.selectedType }]
                : root.typeOptions
            textRole: "text"
            valueRole: "value"
            currentIndex: root.typeOptions.findIndex(option => option.value === root.selectedType) >= 0
                ? root.typeOptions.findIndex(option => option.value === root.selectedType)
                : root.typeOptions.length
            onActivated: index => root.selectedType = model[index].value
        }
    }

    FormCard.FormCard {
        Layout.topMargin: Kirigami.Units.smallSpacing

        FormCard.FormTextFieldDelegate {
            id: streetField
            objectName: "addressStreetField"
            label: KI18n.i18nc("@label:textbox", "Street")
            text: root.originalAddress?.street ?? ""
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            id: extendedField
            label: KI18n.i18nc("@label:textbox", "Apartment, suite, etc.")
            text: root.originalAddress?.extended ?? ""
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            id: postOfficeBoxField
            label: KI18n.i18nc("@label:textbox", "P.O. box")
            text: root.originalAddress?.postOfficeBox ?? ""
        }
    }

    FormCard.FormGridContainer {
        Layout.topMargin: Kirigami.Units.smallSpacing

        FormCard.FormTextFieldDelegate {
            id: cityField
            objectName: "addressCityField"
            label: KI18n.i18nc("@label:textbox", "City")
            text: root.originalAddress?.locality ?? ""
        }

        FormCard.FormTextFieldDelegate {
            id: regionField
            label: KI18n.i18nc("@label:textbox", "State or region")
            text: root.originalAddress?.region ?? ""
        }

        FormCard.FormTextFieldDelegate {
            id: postalCodeField
            label: KI18n.i18nc("@label:textbox", "Postal code")
            text: root.originalAddress?.postalCode ?? ""
        }

        FormCard.FormTextFieldDelegate {
            id: countryField
            label: KI18n.i18nc("@label:textbox", "Country")
            text: root.originalAddress?.country ?? ""
        }
    }

    FormCard.FormCard {
        Layout.topMargin: Kirigami.Units.smallSpacing

        FormCard.FormTextFieldDelegate {
            id: labelField
            label: KI18n.i18nc("@label:textbox", "Delivery label")
            text: root.originalAddress?.label ?? ""
        }
    }

    footer: ColumnLayout {
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.DialogButtonBox {
            Layout.fillWidth: true
            standardButtons: QQC2.DialogButtonBox.Cancel

            QQC2.Button {
                visible: root.row >= 0
		width: visible ? implicitWidth : 0
                icon.name: "edit-delete-symbolic"
                text: KI18n.i18nc("@action:button", "Remove address")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.DestructiveRole
                onClicked: {
                    root.addressModel.deleteAddress(root.row);
                    root.Kirigami.PageStack.closeDialog();
                }
            }

            QQC2.Button {
                objectName: "saveAddressButton"
                icon.name: "document-save-symbolic"
                text: KI18n.i18nc("@action:button", "Save")
                enabled: root.hasAddressDetails
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: root.Kirigami.PageStack.closeDialog()
            onAccepted: {
                root.saveAddress();
                root.Kirigami.PageStack.closeDialog();
            }
        }
    }
}
