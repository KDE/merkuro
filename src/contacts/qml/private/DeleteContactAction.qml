// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.contact

Kirigami.Action {
    property string name
    property var item

    readonly property Component deleteContactConfirmationDialogComponent: Component {
        id: deleteContactConfirmationDialogComponent
        Components.MessageDialog {
            id: deleteContactConfirmationDialog

            title: i18nc("@title:dialog", "Confirm Contact Deletion")

            dialogType: Components.MessageDialog.Warning

            contentItem: QQC2.Label {
                text: i18n("Do you really want to delete your contact: <b>%1</b>?", name.trim().length > 0 ? name : i18nc("Placeholder when no name is set", "No name")) + " " +i18n("You won't be able to revert this action")
                wrapMode: Text.WordWrap
                leftPadding: Kirigami.Units.largeSpacing * 2
                rightPadding: Kirigami.Units.largeSpacing * 2
            }

            onRejected: deleteContactConfirmationDialog.close()
            onAccepted: {
                ContactManager.deleteItem(item)
                if (applicationWindow().pageStack.depth > 1) {
                    applicationWindow().pageStack.pop()
                }
                deleteContactConfirmationDialog.close();
            }

            footer: QQC2.DialogButtonBox {
                leftPadding: Kirigami.Units.largeSpacing * 2
                rightPadding: Kirigami.Units.largeSpacing * 2
                bottomPadding: Kirigami.Units.largeSpacing * 2
                topPadding: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Cancel")
                    QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
                }
                QQC2.Button {
                    text: i18n("Delete contact")
                    QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
                }
            }
        }
    }

    icon.name: "delete"
    text: i18nc("@action:inmenu", "Delete contact")
    onTriggered: {
        const dialog = deleteContactConfirmationDialogComponent.createObject(applicationWindow())
        dialog.open()
    }
}
