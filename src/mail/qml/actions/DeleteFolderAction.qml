// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.mail
import org.kde.ki18n

Kirigami.Action {
    property var index
    property string name

    readonly property Component deleteFolderDialogComponent: Component {
        id: deleteFolderDialogComponent

        Kirigami.PromptDialog {
            id: deleteFolderDialog
            title: KI18n.i18n("Delete Folder")
            standardButtons: Kirigami.Dialog.NoButton

            customFooterActions: [
                Kirigami.Action {
                    text: KI18n.i18n("Delete Folder")
                    icon.name: "dialog-ok"
                    onTriggered: {
                        MailManager.deleteCollection(index);
                        deleteFolderDialog.close();
                    }
                },
                Kirigami.Action {
                    text: KI18n.i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onTriggered: deleteFolderDialog.close() 
                }
            ]

            QQC2.TextArea {
                text: KI18n.i18n("Are you sure you want to delete the folder %1, discarding its contents? <br /> <b>Beware</b> that discarded messages are not saved into your Trash folder and are permanently deleted.", name.toUpperCase())
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
