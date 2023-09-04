// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15 
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.merkuro.mail 1.0

Kirigami.Action {
    required property var index

    readonly property Component newFolderDialogComponent: Component {
        id: newFolderDialogComponent

        Kirigami.PromptDialog {
            id: newFolderDialog
            title: i18n("New Folder")
            standardButtons: Kirigami.Dialog.NoButton

            customFooterActions: [
                Kirigami.Action {
                    text: i18n("Create Folder")
                    icon.name: "dialog-ok"
                    onTriggered: {
                        MailManager.addCollection(index, newFolderName.text);
                        newFolderDialog.close();
                    }
                },
                Kirigami.Action {
                    text: i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onTriggered: newFolderDialog.close() 
                }
            ]

            QQC2.TextField {
                id: newFolderName
                placeholderText: i18n("Folder Name...")
            }
        }
    }

    onTriggered: {
        const dialog = newFolderDialogComponent.createObject(applicationWindow());
        dialog.open();
    }
}