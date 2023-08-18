// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15 
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.merkuro.mail 1.0

Kirigami.Action {
    property var index
    property string name

    readonly property Component deleteFolderDialogComponent: Component {
        id: deleteFolderDialogComponent

        Kirigami.PromptDialog {
            id: deleteFolderDialog
            title: i18n("Delete Folder")
            standardButtons: Kirigami.Dialog.NoButton

            customFooterActions: [
                Kirigami.Action {
                    text: i18n("Delete Folder")
                    icon.name: "dialog-ok"
                    onTriggered: {
                        MailManager.deleteCollection(index);
                        deleteFolderDialog.close();
                    }
                },
                Kirigami.Action {
                    text: i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onTriggered: deleteFolderDialog.close() 
                }
            ]

            QQC2.TextArea {
                text: i18n("Are you sure you want to delete the folder %1, discarding its contents? <br /> <b>Beware</b> that discarded messages are not saved into your Trash folder and are permanently deleted.", name.toUpperCase())
                textFormat: TextEdit.RichText
                background: null
                readOnly: true
                wrapMode: TextEdit.Wrap
            }
        }
    }

    onTriggered: {
        const dialog = deleteFolderDialogComponent.createObject(applicationWindow());
        dialog.open();
    }
}