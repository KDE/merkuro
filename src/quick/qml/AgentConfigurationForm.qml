// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import org.kde.akonadi
import org.kde.merkuro.calendar

FormCard.FormCard {
    id: root

    required property var mimetypes
    required property string addPageTitle

    readonly property AgentConfiguration _configuration: AgentConfiguration {
        mimetypes: root.mimetypes
        onErrorOccurred: (error) => root.QQC2.ApplicationWindow.window.showPassiveNotification(error)
    }

    Components.MessageDialog {
        id: dialog

        property Item agentDelegate

        title: i18n("Configure %1", agentDelegate?.name)
        parent: root.QQC2.Overlay.overlay
        standardButtons: Kirigami.Dialog.NoButton
        iconName: ''

        QQC2.Label {
            text: i18n("Modify or delete this account agent.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        footer: QQC2.DialogButtonBox {
            leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            topPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18nc("@action:button", "Modify")
                icon.name: "edit-entry-symbolic"
                onClicked: {
                    root._configuration.edit(dialog.agentDelegate.index);
                    dialog.close();
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "Delete")
                icon.name: "delete-symbolic"
                onClicked: {
                    root._configuration.remove(dialog.agentDelegate.index);
                    dialog.close();
                }
                enabled: root._configuration.isRemovable(dialog.agentDelegate?.index)
            }
        }
    }


    Repeater {
        model: root._configuration.runningAgents
        delegate: FormCard.FormButtonDelegate {
            id: agentDelegate

            required property int index
            required property string iconName
            required property string name
            required property string statusMessage
            required property bool online

            leadingPadding: Kirigami.Units.largeSpacing
            leading: Kirigami.Icon {
                source: agentDelegate.iconName
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
            }

            text: name
            description: statusMessage

            onClicked: {
                dialog.agentDelegate = agentDelegate;
                dialog.open();
            }
        }
    }

    FormCard.FormDelegateSeparator { below: addAccountDelegate }

    FormCard.FormButtonDelegate {
        id: addAccountDelegate
        text: i18n("Add Account")
        icon.name: "list-add"
        onClicked: pageStack.pushDialogLayer(addAccountPage)
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
                model: root._configuration.availableAgents
                delegate: Delegates.RoundedItemDelegate {
                    id: agentDelegate

                    required property int index
                    required property string name
                    required property string iconName
                    required property string description

                    text: name
                    icon.name: iconName

                    contentItem: Delegates.SubtitleContentItem {
                        itemDelegate: agentDelegate
                        subtitle: agentDelegate.description
                        subtitleItem.wrapMode: Text.Wrap
                    }

                    enabled: root._configuration.availableAgents.flags(root._configuration.availableAgents.index(index, 0)) & Qt.ItemIsEnabled
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
