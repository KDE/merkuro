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
    property alias toAddEmailText: toAddEmail.text
    property alias newEmailTypeCurrentValue: newEmailType.currentValue

    Repeater {
        id: emailRepeater
        model: root.contactEditor.contact.emailModel

        delegate: FormCard.AbstractFormDelegate {
            id: emailRow
            Layout.fillWidth: true
            contentItem: RowLayout {
                QQC2.ComboBox {
                    id: emailTypeBox
                    model: ListModel {id: emailTypeModel; dynamicRoles: true }
                    Component.onCompleted: {
                        [
                            { value: EmailModel.Unknown, text: i18n("Unknown") },
                            { value: EmailModel.Home, text: i18n("Home") },
                            { value: EmailModel.Work, text: i18n("Work") },
                            { value: EmailModel.Other, text: i18n("Other") }
                        ].forEach((type) => {
                            emailTypeModel.append(type);
                        });
                    }
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: typeValue
                    onCurrentValueChanged: type = currentValue
                }
                QQC2.TextField {
                    id: textField
                    Layout.fillWidth: true
                    text: model.display
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    onTextChanged: model.display = text;
                }
                QQC2.Button {
                    icon.name: "list-remove"
                    implicitWidth: implicitHeight
                    QQC2.ToolTip {
                        text: i18n("Remove email")
                    }
                    onClicked: root.contactEditor.contact.emailModel.deleteEmail(index)
                }
            }
        }
    }
    FormCard.AbstractFormDelegate {
        Layout.fillWidth: true
        contentItem: RowLayout {
            visible: !root.saving
            QQC2.ComboBox {
                id: newEmailType
                model: ListModel {id: newEmailTypeModel; dynamicRoles: true }
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                Component.onCompleted: {
                    [
                        { value: EmailModel.Home, text: i18n("Home") },
                        { value: EmailModel.Work, text: i18n("Work") },
                        { value: EmailModel.Both, text: i18n("Both") },
                        { value: EmailModel.Other, text: i18n("Other…") }
                    ].forEach((type) => {
                        newEmailTypeModel.append(type);
                    });
                }
            }
            QQC2.TextField {
                id: toAddEmail
                Layout.fillWidth: true
                placeholderText: i18n("user@example.org")
                inputMethodHints: Qt.ImhEmailCharactersOnly
            }

            QQC2.Button {
                icon.name: "list-add"
                implicitWidth: implicitHeight
                enabled: isNotEmptyStr(toAddEmail.text)
                QQC2.ToolTip {
                    text: i18n("Add email")
                }
                onClicked: {
                    root.contactEditor.contact.emailModel.addEmail(toAddEmail.text, newEmailType.currentValue);
                    toAddEmail.text = '';
                    newEmailType.currentIndex = 0;
                }
            }
        }
    }
}
