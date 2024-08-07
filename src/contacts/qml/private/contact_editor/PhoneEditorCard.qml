// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor
    property alias phoneText: toAddPhone.text
    property alias newPhoneTypeComboText: newPhoneTypeCombo.currentValue

    Repeater {
        id: phoneRepeater
        model: root.contactEditor.contact.phoneModel

        delegate: FormCard.AbstractFormDelegate {
            Layout.fillWidth: true

            contentItem: RowLayout {
                QQC2.ComboBox {
                    model: ListModel {id: phoneTypeModel; dynamicRoles: true }
                    Component.onCompleted: {
                        [
                            { value: PhoneModel.Home, text: i18n("Home") },
                            { value: PhoneModel.Work, text: i18n("Work") },
                            { value: PhoneModel.Msg, text: i18n("Messaging") },
                            { value: PhoneModel.Voice, text: i18n("Voice") },
                            { value: PhoneModel.Fax, text: i18n("Fax") },
                            { value: PhoneModel.Cell, text: i18n("Cell") },
                            { value: PhoneModel.Video, text: i18n("Video") },
                            { value: PhoneModel.Bbs, text: i18n("Mailbox") },
                            { value: PhoneModel.Modem, text: i18n("Modem") },
                            { value: PhoneModel.Car, text: i18n("Car") },
                            { value: PhoneModel.Isdn, text: i18n("ISDN") },
                            { value: PhoneModel.Psc, text: i18n("PCS") },
                            { value: PhoneModel.Pager, text: i18n("Pager") },
                            { value: PhoneModel.Undefined, text: i18n("Undefined") },
                        ].forEach((type) => {
                            phoneTypeModel.append(type);
                        });
                        currentIndex = indexOfValue(typeValue)
                    }
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: type = currentValue
                }
                QQC2.TextField {
                    id: phoneField
                    text: model.display
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                    Layout.fillWidth: true
                    onTextChanged: model.display = text
                }
                QQC2.Button {
                    icon.name: "list-remove"
                    implicitWidth: implicitHeight
                    onClicked: root.contactEditor.contact.phoneModel.deletePhoneNumber(index)
                }
            }
        }
    }

    FormCard.AbstractFormDelegate {
        Layout.fillWidth: true
        contentItem: RowLayout {
            visible: !root.saving
            QQC2.ComboBox {
                id: newPhoneTypeCombo
                model: ListModel {id: phoneTypeModel; dynamicRoles: true }
                Component.onCompleted: {
                    [
                        { value: PhoneModel.Home, text: i18n("Home") },
                        { value: PhoneModel.Work, text: i18n("Work") },
                        { value: PhoneModel.Msg, text: i18n("Messaging") },
                        { value: PhoneModel.Voice, text: i18n("Voice") },
                        { value: PhoneModel.Fax, text: i18n("Fax") },
                        { value: PhoneModel.Cell, text: i18n("Cell") },
                        { value: PhoneModel.Video, text: i18n("Video") },
                        { value: PhoneModel.Bbs, text: i18n("Mailbox") },
                        { value: PhoneModel.Modem, text: i18n("Modem") },
                        { value: PhoneModel.Car, text: i18n("Car") },
                        { value: PhoneModel.Isdn, text: i18n("ISDN") },
                        { value: PhoneModel.Psc, text: i18n("PCS") },
                        { value: PhoneModel.Pager, text: i18n("Pager") }
                    ].forEach((type) => {
                        phoneTypeModel.append(type);
                    });
                }
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
            }
            QQC2.TextField {
                id: toAddPhone
                Layout.fillWidth: true
                placeholderText: i18n("+33 7 55 23 68 67")
                inputMethodHints: Qt.ImhDialableCharactersOnly
            }

            // button to add additional text field
            QQC2.Button {
                icon.name: "list-add"
                implicitWidth: implicitHeight
                enabled: isNotEmptyStr(toAddPhone.text)
                onClicked: {
                    root.contactEditor.contact.phoneModel.addPhoneNumber(toAddPhone.text, newPhoneTypeCombo.currentValue)
                    toAddPhone.text = '';
                    newPhoneTypeCombo.currentIndex = 0;
                }
            }
        }
    }
}
