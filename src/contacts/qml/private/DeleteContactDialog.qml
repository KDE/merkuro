// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import org.kde.ki18n

Components.MessageDialog {
    id: root

    required property list<Akonadi.item> items
    required property list<string> names
    property int pendingDeletions: 0

    title: KI18n.i18nc("@title:dialog", "Confirm Contact Deletion")
    dialogType: Components.MessageDialog.Warning
    standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Ok

    Component.onCompleted: {
        const deleteButton = standardButton(QQC2.Dialog.Ok);
        deleteButton.text = KI18n.i18ncp("@action:button", "Delete contact", "Delete contacts", items.length);
        deleteButton.icon.name = 'delete-symbolic';
        deleteButton.enabled = Qt.binding(() => root.pendingDeletions === 0);
    }

    QQC2.Label {
        text: {
            let msg = KI18n.i18ncp("@info", "Do you really want to delete your contact:", "Do you really want to delete your contacts:", items.length) + '<ul>';

            for (let name of root.names) {
                msg += '<li><b>' + name + '</b></li>';
            }

            msg += '<ul><br />' + KI18n.i18n("You won't be able to revert this action.");
            return msg;
        }
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    function finishPendingDeletion(job: var): void {
        if (job.error) {
            ContactManager.errorOccurred(job.errorString);
        }
        root.pendingDeletions--;
        if (root.pendingDeletions === 0 && root.QQC2.ApplicationWindow.window.pageStack.depth > 1) {
            root.QQC2.ApplicationWindow.window.pageStack.pop()
        }
    }

    onRejected: root.close()
    onAccepted: {
        root.pendingDeletions = items.length;
        for (let item of items) {
            const job = ContactManager.deleteItem(item);
            job.result.connect(root.finishPendingDeletion);
        }
    }
}
