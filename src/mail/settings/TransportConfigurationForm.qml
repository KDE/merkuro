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

    Components.MessageDialog {
        id: dialog

        property var transportDelegate

        title: i18ndc("libakonadi6", "@title:dialog", "Configure %1", transportDelegate?.name)
        parent: root.QQC2.Overlay.overlay
        standardButtons: Kirigami.Dialog.NoButton
        iconName: ''

        QQC2.Label {
            text: i18ndc("libakonadi6", "@info", "Modify or delete this account transport.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        footer: QQC2.DialogButtonBox {
            leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            topPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

            standardButtons: QQC2.Dialog.Cancel

            onRejected: dialog.close()

            QQC2.Button {
                text: i18ndc("libakonadi6", "@action:button", "Modify")
                icon.name: "edit-entry-symbolic"
                onClicked: {
                    root._configuration.edit(dialog.transportDelegate.transportIdentifier);
                    dialog.close();
                }
            }

            QQC2.Button {
                text: i18ndc("libakonadi6", "@action:button", "Delete")
                icon.name: "delete-symbolic"
                onClicked: {
                    root._configuration.remove(dialog.transportDelegate.transportIdentifier);
                    dialog.close();
                }
                enabled: root._configuration.isRemovable(dialog.transportDelegate?.transportIdentifier)
            }
        }
    }


    Repeater {
        id: transportsRepeater

        model: root._configuration.transportModel
        delegate: FormCard.FormButtonDelegate {
            id: transportDelegate

            required property int index
            required property string name
            required property string transportIdentifier

            text: name

            onClicked: {
                dialog.transportDelegate = transportDelegate;
                dialog.open();
            }
        }
    }

    FormCard.FormDelegateSeparator {
        below: addAccountDelegate
        visible: transportsRepeater.count > 0
    }

    FormCard.FormButtonDelegate {
        id: addAccountDelegate
        text: i18ndc("libakonadi6", "@action:button", "Add Account")
        icon.name: "list-add-symbolic"
        onClicked: (root.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack.pushDialogLayer(addAccountPage)
    }

    data: Component {
        id: addAccountPage
        Kirigami.ScrollablePage {
            id: overlay
            title: root.addPageTitle

            footer: QQC2.ToolBar {
                width: parent.width

                contentItem: QQC2.DialogButtonBox {
                    padding: 0
                    standardButtons: QQC2.DialogButtonBox.Close
                    onRejected: closeDialog()
                }
            }

            ListView {
                implicitWidth: Kirigami.Units.gridUnit * 20
                model: root._configuration.availableTransportTypes
                delegate: Delegates.RoundedItemDelegate {
                    id: transportTypeDelegate

                    required property int index
                    required property string name
                    required property string description

                    text: name

                    contentItem: Delegates.SubtitleContentItem {
                        itemDelegate: transportTypeDelegate
                        subtitle: transportTypeDelegate.description
                        subtitleItem.wrapMode: Text.Wrap
                    }

                    onClicked: {
                        root._configuration.createNew(index);
                        overlay.closeDialog();
                        overlay.destroy();
                    }
                }
            }
        }
    }
}
