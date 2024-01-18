// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import Qt.labs.platform 1.1
import QtQuick.Dialogs 6.2
import org.kde.merkuro.mail 1.0
import org.kde.kitemmodels 1.0 as KItemModels
import './private'

Kirigami.ScrollablePage {
    id: folderView
    title: MailManager.selectedFolderName

    property var collection

    Loader {
        id: mailSaveLoader

        active: false
        onLoaded: item.open();
        
        sourceComponent: FileDialog {
            title: i18n("Save Message - Merkuro-Mail")
            nameFilters: [i18n("email messages (*.mbox)")]
            currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
            fileMode: fileDialog.SaveFile

            onAccepted: {
                if (fileUrl) {
                    MailManager.saveMail(fileUrl, folderView.collection);
                }
                mailSaveLoader.active = false;
            }
            onRejected: mailSaveLoader.active = false;
        }
    }

    actions: Kirigami.Action {
        icon.name: 'mail-send'
        text: i18nc("@action:menu", "Create")
        onTriggered: applicationWindow().pageStack.pushDialogLayer(Qt.resolvedUrl("./MailComposer.qml"))
    }

    ListView {
        id: mails
        model: MailManager.folderModel
        currentIndex: -1

        Component {
            id: contextMenu
            QQC2.Menu {
                property int row
                property var status

                QQC2.Menu {
                    title: i18nc("@action:menu", "Mark Message")
                    QQC2.MenuItem {
                        text: i18n("Mark Message as Read")
                    }
                    QQC2.MenuItem {
                        text: i18n("Mark Message as Unread")
                    }

                    QQC2.MenuSeparator {}

                    QQC2.MenuItem {
                        text: status.isImportant ? i18n("Don't Mark as Important") : i18n("Mark as Important")
                    }
                }

                QQC2.MenuItem {
                    icon.name: 'delete'
                    text: i18n("Move to Trash")
                }

                QQC2.MenuItem {
                    icon.name: 'edit-move'
                    text: i18n("Move Message to...")
                }

                QQC2.MenuItem {
                    icon.name: 'edit-copy'
                    text: i18n("Copy Message to...")
                }

                QQC2.MenuItem {
                    icon.name: 'view-calendar'
                    text: i18n("Add Followup Reminder")
                }

                QQC2.MenuItem {
                    icon.name: 'document-save-as'
                    text: i18nc("@action:button", "Save as...")
                    onClicked: mailSaveLoader.active = true 
                }
            }
        }

        Connections {
            target: MailManager

            function onFolderModelChanged() {
                mails.currentIndex = -1;
            }
        }

        Kirigami.PlaceholderMessage {
            id: mailboxSelected
            anchors.centerIn: parent
            visible: MailManager.selectedFolderName === ""
            text: i18n("No mailbox selected")
            explanation: i18n("Select a mailbox from the sidebar.")
            icon.name: "mail-unread"
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            visible: mails.count === 0 && !mailboxSelected.visible
            text: i18n("Mailbox is empty")
            icon.name: "mail-folder-inbox"
        }

        section.delegate: Kirigami.ListSectionHeader {
            required property string section
            label: section
        }
        section.property: "date"

        delegate: MailDelegate {
            id: mailDelegate

            onOpenMailRequested: {
                applicationWindow().pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    emptyItem: mailDelegate.item,
                    props: {
                        from: mailDelegate.from,
                        to: mailDelegate.to,
                        sender: mailDelegate.sender,
                        item: mailDelegate.item,
                        title: mailDelegate.title,
                    }
                });

                if (!mailDelegate.status.isRead) {
                    const status = MailManager.folderModel.copyMessageStatus(mailDelegate.status);
                    status.isRead = true;
                    MailManager.folderModel.updateMessageStatus(index, status)
                }
            }

            onStarMailRequested: {
                const status = MailManager.folderModel.copyMessageStatus(mailDelegate.status);
                status.isImportant = !status.isImportant;
                MailManager.folderModel.updateMessageStatus(index, status)
            }

            onContextMenuRequested: {
                const menu = contextMenu.createObject(folderView, {
                    row: index,
                    status: MailManager.folderModel.copyMessageStatus(mailDelegate.status),
                });
                folderView.collection = mailDelegate.item;
                menu.popup();
            }
        }
    }
}