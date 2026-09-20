// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.mail
import org.kde.ki18n

Kirigami.Action {
    required property var index

    readonly property Component newFolderDialogComponent: Component {
        id: newFolderDialogComponent

        Kirigami.PromptDialog {
            id: newFolderDialog
            title: KI18n.i18n("New Folder")
            standardButtons: Kirigami.Dialog.NoButton

            customFooterActions: [
                Kirigami.Action {
                    text: KI18n.i18n("Create Folder")
                    icon.name: "dialog-ok"
                    onTriggered: {
                        MailManager.addCollection(index, newFolderName.text);
                        newFolderDialog.close();
                    }
                },
                Kirigami.Action {
                    text: KI18n.i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onTriggered: newFolderDialog.close() 
                }
            ]

            QQC2.TextField {
                id: newFolderName
                placeholderText: KI18n.i18n("Folder Name…")
            }
        }
    }

    onTriggered: {
        const dialog = newFolderDialogComponent.createObject(applicationWindow());
        dialog.open();
    }
}
