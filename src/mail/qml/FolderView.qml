// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQml.Models
import org.kde.kirigami as Kirigami
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

    header: QQC2.Pane {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        visible: mailSelectionModel.hasSelection
        height: visible ? implicitHeight: 0

        contentItem: RowLayout {
            spacing: 0

            Kirigami.Heading {
                text: i18ncp("Number of selected emails", "%1 selected", "%1 selected", mailSelectionModel.selectedIndexes.length)
                level: 2
                elide: Text.ElideRight
            }

            Kirigami.ActionToolBar {
                Layout.fillWidth: true
                actions: [
                    QQC2.Action {
                        text: i18nc("@action:intoolbar", "Delete")
                        icon.name: 'edit-delete-symbolic'
                    },
                    QQC2.Action {
                        text: i18nc("@action:intoolbar", "Mark read")
                        icon.name: 'mail-mark-read-symbolic'
                        onTriggered: mailActions.setReadState(true)
                    },
                    QQC2.Action {
                        text: i18nc("@action:intoolbar", "Mark unread")
                        icon.name: 'mail-mark-unread-symbolic'
                        onTriggered: mailActions.setReadState(false)
                    },
                    QQC2.Action {
                        text: i18nc("@action:intoolbar", "Forward as attachment")
                        icon.name: 'mail-forwarded-symbolic'
                    }
                ]
            }

            QQC2.ToolButton {
                text: i18nc("@action:button", "Cancel")
                icon.name: 'edit-select-none-symbolic'
                onClicked: mailSelectionModel.clear()
            }
        }

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

    ListView {
        id: mails
        model: root.searchString.length > 0 ? searchModel : mailModel
        currentIndex: -1
        clip: true

        ItemSelectionModel {
            id: mailSelectionModel
            model: mails.model
        }

        MailActions {
            id: mailActions
            selectionModel: mailSelectionModel
        }

        Component {
            id: contextMenu
            QQC2.Menu {
                QQC2.Menu {
                    title: i18nc("@action:menu", "Mark Message")
                    QQC2.MenuItem {
                        text: i18ncp("@action:inmenu", "Mark Message as Read", "Mark Messages as Read", mailSelectionModel.selectedIndexes.length)
                        onClicked: mailActions.setReadState(true)
                    }
                    QQC2.MenuItem {
                        text: i18ncp("@action:inmenu", "Mark Message as Unread", "Mark Messages as Unread", mailSelectionModel.selectedIndexes.length)
                        onClicked: mailActions.setReadState(false)
                    }

                    QQC2.MenuSeparator {}

                    QQC2.MenuItem {
                        text: i18ncp("@action:inmenu", "Mark Message as Important", "Mark Messages as Important", mailSelectionModel.selectedIndexes.length)
                        onClicked: mailActions.setImportantState(true)
                    }

                    QQC2.MenuItem {
                        text: i18ncp("@action:inmenu", "Mark Message as Unimportant", "Mark Messages as Uninportant", mailSelectionModel.selectedIndexes.length)
                        onClicked: mailActions.setImportantState(false)
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

            selectionModel: mailSelectionModel

            onOpenMailRequested: {
                mails.currentIndex = index;
                mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mailDelegate.index, 0), ItemSelectionModel.Current);

                applicationWindow().pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    emptyItem: mailDelegate.item,
                    props: {
                        from: mailDelegate.from,
                        to: mailDelegate.to,
                        sender: mailDelegate.sender,
                        item: mailDelegate.item,
                        title: mailDelegate.title,
                    },
                });

                if (!mailDelegate.status.isRead) {
                    mailActions.setReadState(true);
                }

            }

            onStarMailRequested: {
                mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mailDelegate.index, 0), ItemSelectionModel.Current);
                mailActions.setImportantState(!status.isImportant);
            }

            onContextMenuRequested: {
                const menu = contextMenu.createObject(folderView);
                folderView.collection = mailDelegate.item;
                menu.popup();
            }
        }
    }
}
