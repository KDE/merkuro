// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2
import Qt.labs.platform
import QtQuick.Dialogs
import org.kde.merkuro.mail
import org.kde.merkuro.components
import org.kde.kitemmodels as KItemModels
import './private'

Kirigami.ScrollablePage {
    id: folderView

    property var collection
    property alias searchString: searchModel.searchString

    title: searchString.length > 0 ? i18nc("@title", "Search: %1", searchString) : mailModel.folderName

    MailModel {
        id: mailModel

        collectionSelectionModel: MailManager.collectionSelectionModel
        entryTreeModel: MailManager.entryTreeModel
        onFolderNameChanged: {
            mails.currentIndex = -1
        }
    }

    SearchModel {
        id: searchModel
    }

    Loader {
        id: mailSaveLoader

        active: false
        onLoaded: item.open();

        sourceComponent: FileDialog {
            title: i18n("Save Message - Merkuro-Mail")
            nameFilters: [i18n("email messages (*.mbox)")]
            currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
            fileMode: FileDialog.SaveFile

            onAccepted: {
                if (fileUrl) {
                    MailManager.saveMail(fileUrl, folderView.collection);
                }
                mailSaveLoader.active = false;
            }
            onRejected: mailSaveLoader.active = false;
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: 'mail-send'
            text: i18nc("@action:menu", "Create")
            onTriggered: applicationWindow().pageStack.pushDialogLayer(Qt.resolvedUrl("./MailComposer.qml"))
        },
        Kirigami.Action {
            fromQAction: MailApplication.action("check_mail")
            visible: folderView.searchString.length === 0
        }
    ]

    ListView {
        id: mails
        model: root.searchString.length > 0 ? searchModel : mailModel
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
                    const status = mailModel.copyMessageStatus(mailDelegate.status);
                    status.isRead = true;
                    mailModel.updateMessageStatus(index, status)
                }
            }

            onStarMailRequested: {
                const status = mailModel.copyMessageStatus(mailDelegate.status);
                status.isImportant = !status.isImportant;
                mailModel.updateMessageStatus(index, status)
            }

            onContextMenuRequested: {
                const menu = contextMenu.createObject(folderView, {
                    row: index,
                    status: mailModel.copyMessageStatus(mailDelegate.status),
                });
                folderView.collection = mailDelegate.item;
                menu.popup();
            }
        }
    }
}
