// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor

    Repeater {
        model: root.contactEditor.contact.imppModel

        delegate: FormCard.AbstractFormDelegate {
            id: imppDelegate

            required property int index
            required property string url
            required property var model

            background: null
            Layout.fillWidth: true

            contentItem: RowLayout {
                QQC2.TextField {
                    id: imppField
                    text: imppDelegate.url
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    Layout.fillWidth: true
                    onTextChanged: imppDelegate.model.url = text
                }

                QQC2.Button {
                    icon.name: "list-remove"
                    implicitWidth: implicitHeight
                    onClicked: root.contactEditor.contact.imppModel.deleteImpp(imppDelegate.index);
                }
            }
        }
    }

    FormCard.AbstractFormDelegate {
        background: null
        Layout.fillWidth: true
        contentItem: RowLayout {
            QQC2.ComboBox {
                id: newService
                editable: true
                model: ImppServiceListModel {}
                textRole: "display"
                valueRole: "serviceType"
            }

            QQC2.TextField {
                id: newUsername
                Layout.fillWidth: true
                placeholderText: i18n("@person:example.com")
                inputMethodHints: Qt.ImhEmailCharactersOnly
            }

            // button to add additional text field
            QQC2.Button {
                icon.name: "list-add"
                implicitWidth: implicitHeight
                enabled: isNotEmptyStr(newUsername.text)
                onClicked: {
                    // Hack-y: The goal is to get the current value of the model if the user has not
                    //         edited the display text, otherwise use the value the user inputed.
                    const serviceType =
                          (newService.currentText === newService.editText) ?
                          newService.currentValue : newService.editText;
                    root.contactEditor.contact.imppModel.addImpp(`${serviceType}:${newUsername.text}`);
                    newUsername.text = "";
                }
            }
        }
    }
}
