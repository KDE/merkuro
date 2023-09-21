// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import org.kde.merkuro.contact 1.0
import org.kde.akonadi 1.0 as Akonadi

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
            QQC2.TextField {
                id: toAddImpp
                Layout.fillWidth: true
                placeholderText: i18n("protocol:person@example.com")
                inputMethodHints: Qt.ImhEmailCharactersOnly
            }

            // button to add additional text field
            QQC2.Button {
                icon.name: "list-add"
                implicitWidth: implicitHeight
                enabled: isNotEmptyStr(toAddImpp.text)
                onClicked: {
                    root.contactEditor.contact.imppModel.addImpp(toAddImpp.text);
                    toAddImpp.text = "";
                }
            }
        }
    }

    //KirigamiDateTime.DateInput {
    //    id: birthday
    //    Kirigami.FormData.label: i18n("Birthday:")

    //    selectedDate: addressee.birthday

    //    Connections {
    //        target: root
    //        function onSave() {
    //            addressee.birthday = birthday.selectedDate // TODO birthday is not writable
    //        }
    //    }
    //}
}
