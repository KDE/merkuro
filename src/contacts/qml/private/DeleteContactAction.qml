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
        QQC2.Dialog {
            id: deleteContactConfirmationDialog
            visible: false
            title: i18nc("@title:window", "Warning")
            modal: true
            focus: true
            x: Math.round((parent.width - width) / 2)
            y: Math.round(parent.height / 3)
            width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 30)

            background: Components.DialogRoundedBackground {}

            contentItem: RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        level: 4
                        text: i18n("Do you really want to delete your contact: \"%1\"?", name.trim().length > 0 ? name : i18nc("Placeholder when no name is set", "No name"))
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    QQC2.Label {
                        text: i18n("You won't be able to revert this action")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Kirigami.Icon {
                    source: "data-warning"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                }
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
