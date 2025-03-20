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

Components.MessageDialog {
    id: root

    required property list<Akonadi.item> items
    required property list<string> names

    title: i18nc("@title:dialog", "Confirm Contact Deletion")
    dialogType: Components.MessageDialog.Warning
    standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Ok

    Component.onCompleted: {
        const deleteButton = standardButton(QQC2.Dialog.Ok);
        deleteButton.text = i18ncp("@action:button", "Delete contact", "Delete contacts", items.length);
        deleteButton.icon.name = 'delete-symbolic';
    }

    QQC2.Label {
        text: i18n("Do you really want to delete your contact: <b>%1</b>?") + names.join(',') + " " + i18n("You won't be able to revert this action")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    onRejected: root.close()
    onAccepted: {
        for (let item of items) {
            ContactManager.deleteItem(item)
        }
        if (root.QQC2.ApplicationWindow.window.pageStack.depth > 1) {
            root.QQC2.ApplicationWindow.window.pageStack.pop()
        }
        root.close();
    }
}
