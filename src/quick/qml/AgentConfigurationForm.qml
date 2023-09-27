// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.akonadi

FormCard.FormCard {
    id: root

    required property var mimetypes
    required property string addPageTitle

    readonly property AgentConfiguration _configuration: AgentConfiguration {
        mimetypes: root.mimetypes
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

            Loader {
                id: dialogLoader
                sourceComponent: Kirigami.PromptDialog {
                    id: dialog
                    title: i18n("Configure %1", agentDelegate.name)
                    subtitle: i18n("Modify or delete this account agent.")
                    standardButtons: Kirigami.Dialog.NoButton

                    customFooterActions: [
                        Kirigami.Action {
                            text: i18n("Modify")
                            icon.name: "edit-entry"
                            onTriggered: {
                                root._configuration.edit(agentDelegate.index);
                                dialog.close();
                            }
                        },
                        Kirigami.Action {
                            text: i18n("Delete")
                            icon.name: "delete"
                            onTriggered: {
                                root._configuration.remove(agentDelegate.index);
                                dialog.close();
                            }
                        }
                    ]
                }
            }

            leadingPadding: Kirigami.Units.largeSpacing
            leading: Kirigami.Icon {
                source: agentDelegate.iconName
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
            }

            text: name
            description: statusMessage

            onClicked: {
                dialogLoader.active = true;
                dialogLoader.item.open();
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
