// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCard {
    id: root

    required property ContactEditor contactEditor
    property alias toAddEmailText: toAddEmail.text
    property alias newEmailTypeCurrentValue: newEmailType.currentValue

    Component.onCompleted: autoSeparators = true

    Repeater {
        id: emailRepeater
        model: root.contactEditor.contact.emailModel

        delegate: FormCard.AbstractFormDelegate {
            id: emailRow
            required property int index
            required property int typeValue
            required property int type
            required property var model
            Layout.fillWidth: true
            contentItem: RowLayout {
                QQC2.ComboBox {
                    id: emailTypeBox
                    model: ListModel {id: emailTypeModel; dynamicRoles: true }
                    Component.onCompleted: {
                        [
                            { value: EmailModel.Unknown, text: KI18n.i18n("Unknown") },
                            { value: EmailModel.Home, text: KI18n.i18n("Home") },
                            { value: EmailModel.Work, text: KI18n.i18n("Work") },
                            { value: EmailModel.Other, text: KI18n.i18n("Other") }
                        ].forEach((type) => {
                            emailTypeModel.append(type);
                        });
                    }
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: emailRow.typeValue
                    onCurrentValueChanged: emailRow.type = currentValue
                }
                QQC2.TextField {
                    id: textField
                    Layout.fillWidth: true
                    text: emailRow.model.display
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    onTextChanged: emailRow.model.display = text;
                }
                QQC2.Button {
                    icon.name: "list-remove"
                    implicitWidth: implicitHeight
                    QQC2.ToolTip {
                        text: KI18n.i18n("Remove email")
                    }
                    onClicked: root.contactEditor.contact.emailModel.deleteEmail(emailRow.index)
                }
            }
        }
    }
    FormCard.AbstractFormDelegate {
        Layout.fillWidth: true
        contentItem: RowLayout {
            visible: !root.contactEditor.saving
            QQC2.ComboBox {
                id: newEmailType
                model: ListModel {id: newEmailTypeModel; dynamicRoles: true }
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                Component.onCompleted: {
                    [
                        { value: EmailModel.Home, text: KI18n.i18n("Home") },
                        { value: EmailModel.Work, text: KI18n.i18n("Work") },
                        { value: EmailModel.Home | EmailModel.Work, text: KI18n.i18n("Both") },
                        { value: EmailModel.Other, text: KI18n.i18n("Other…") }
                    ].forEach((type) => {
                        newEmailTypeModel.append(type);
                    });
                }
            }
            QQC2.TextField {
                id: toAddEmail
                objectName: "toAddEmailField"
                Layout.fillWidth: true
                placeholderText: KI18n.i18n("user@example.org")
                inputMethodHints: Qt.ImhEmailCharactersOnly
            }

            QQC2.Button {
                objectName: "addEmailButton"
                icon.name: "list-add"
                implicitWidth: implicitHeight
                enabled: toAddEmail.text.trim().length > 0
                QQC2.ToolTip {
                    text: KI18n.i18n("Add email")
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
