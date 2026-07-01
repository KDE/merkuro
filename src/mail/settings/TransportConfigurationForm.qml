// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-FileCopyrightText: 2026 Florian Richer <florian.richer@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.mail

FormCard.FormCard {
    id: root

    required property string addPageTitle

    readonly property MailTransportConfiguration _configuration: MailTransportConfiguration {
        id: _configuration
    }

    FormCard.FormCardDialog {
        id: renameDialog

        property var transportDelegate

        title: i18nc("@title:dialog", "Rename %1", transportDelegate.transportName)
        standardButtons:  QQC2.Dialog.Cancel | QQC2.Dialog.Ok
        parent: root.QQC2.Overlay.overlay

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: nameDelegate
                readonly property bool isValid: text.trim().length > 0

                label: i18nc("Ask to the user to enter name for the Outgoing Account", "Account Name")
                placeholderText: transportDelegate.transportName
            }
        }

        onAccepted: {
            root._configuration.rename(transportDelegate.index, nameDelegate.text);
            closeDialog();
        }
    }

    Repeater {
        id: transportsRepeater

        model: root._configuration.transportModel
        delegate: FormCard.FormRadioDelegate {
            id: transportDelegate

            required property int index
            required property string name
            required property string transportName
            required property string transportIdentifier

            text: name
            checked: root._configuration.isDefault(transportIdentifier)

            onClicked: {
                root._configuration.setDefault(transportIdentifier);
            }

            trailing: RowLayout {
                QQC2.ToolButton {
                    icon.name: "entry-edit"
                    onClicked: {
                        renameDialog.transportDelegate = transportDelegate;
                        renameDialog.open();
                    }
                }

                QQC2.ToolButton {
                    icon.name: "settings-configure"
                    onClicked: root._configuration.edit(transportDelegate.transportIdentifier);
                }

                QQC2.ToolButton {
                    icon.name: "delete"
                    onClicked: root._configuration.remove(transportDelegate.transportIdentifier);
                    enabled: root._configuration.isRemovable(transportDelegate.transportIdentifier)
                }
            }
        }
    }

    FormCard.FormDelegateSeparator {
        below: addAccountDelegate
        visible: transportsRepeater.count > 0
    }

    FormCard.FormButtonDelegate {
        id: addAccountDelegate
        text: i18nc("@action:button", "Add Account")
        icon.name: "list-add-symbolic"
        onClicked: (root.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack.pushDialogLayer(addAccountPage)
    }

    data: Component {
        id: addAccountPage
        FormCard.FormCardPage {
            id: overlay
            title: root.addPageTitle

            property int selectedTransportType: -1

            footer: QQC2.ToolBar {
                width: parent.width

                contentItem: QQC2.DialogButtonBox {
                    padding: 0
                    standardButtons: QQC2.DialogButtonBox.Close | QQC2.DialogButtonBox.Ok
                    onRejected: overlay.closeDialog()
                    onAccepted: {
                        root._configuration.createNew(overlay.selectedTransportType, newNameDelegate.text, defaultDelegate.checked);
                        overlay.closeDialog();
                        overlay.destroy();
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("General")
            }

            FormCard.FormCard {
                FormCard.FormTextFieldDelegate {
                    id: newNameDelegate
                    readonly property bool isValid: text.trim().length > 0

                    label: i18nc("Ask to the user to enter name for the Outgoing Account", "Account Name")
                }

                FormCard.FormCheckDelegate {
                    id: defaultDelegate
                    text: i18nc("@action:button Set the outgoing account as the default", "Set as default")
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:header Title of a list of transport types (SMTP, Microsoft Exchange, etc.)", "Select the account type")
            }

            FormCard.FormCard {
                Repeater {
                    model: root._configuration.availableTransportTypes

                    FormCard.FormRadioDelegate {
                        id: transportTypeDelegate

                        required property int index
                        required property var modelData

                        text: modelData.name
                        description: modelData.description

                        checked: overlay.selectedTransportType === index
                        onClicked: overlay.selectedTransportType = index

                        Component.onCompleted: console.warn(modelData.description, modelData)
                    }
                }
            }
        }
    }
}
