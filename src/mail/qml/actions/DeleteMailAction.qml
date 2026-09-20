// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.merkuro.mail
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.ki18n

Controls.Action {
    id: root

    property var item
    property string name

    signal removed

    text: KI18n.i18nc("@action", "Move to Trash")
    icon.name: "albumfolder-user-trash-symbolic"


    readonly property Component deleteMailDialogComponent: Components.MessageDialog {
        id: dialog

        implicitWidth: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 30)
        dontShowAgainName: 'delete-mail'
        title: KI18n.i18nc("@title:dialog", "Delete Email")
        dialogType: Components.MessageDialog.Warning
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel

        onAccepted: {
            MailManager.moveToTrash(root.item);
            root.removed();
            dialog.close();
        }
        onRejected: dialog.close()
        onClosed: dialog.destroy()

        Component.onCompleted: {
            const okButton = dialog.standardButton(Controls.Dialog.Ok)
            okButton.text = KI18n.i18nc("@action:button", "Delete Email")
            okButton.icon.name = "delete-symbolic"
        }

        Kirigami.SelectableLabel {
            text: KI18n.i18n("Are you sure you want to delete the email \"%1\", discarding its contents? <br /> <b>Beware</b> that discarded messages are not saved into your Trash folder and are permanently deleted.", root.name )
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }

    onTriggered: {
        const dialog = deleteMailDialogComponent.createObject(applicationWindow());
        dialog.openDialog();
    }
}
