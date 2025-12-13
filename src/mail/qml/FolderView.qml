// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQml.Models
import org.kde.akonadi as Akonadi
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.mail
import org.kde.merkuro.components
import './private'

Kirigami.ScrollablePage {
    id: root

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

    actions: [
        Kirigami.Action {
            icon.name: 'mail-send'
            text: i18nc("@action:menu", "Create")
            onTriggered: applicationWindow().pageStack.pushDialogLayer(Qt.resolvedUrl("./MailComposer.qml"))
        },
        Kirigami.Action {
            fromQAction: MailApplication.action("check_mail")
            visible: root.searchString.length === 0
        }
    ]

    header: QQC2.Pane {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        visible: mailSelectionModel.hasSelection
        height: visible ? implicitHeight: 0

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            ColoredCheckbox {
                id: checkbox
                checked: true
                onToggled: if (!checked) {
                    mailSelectionModel.clear()
                }
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                indicator {
                    implicitWidth: Kirigami.Units.gridUnit
                    implicitHeight: Kirigami.Units.gridUnit
                }
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing
            }

            Kirigami.Heading {
                text: i18ncp("Number of selected emails", "%1 selected", "%1 selected", mailSelectionModel.selectedIndexes.length)
                level: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                action: Kirigami.Action {
                    fromQAction: MailApplication.action('mail_trash')
                }
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
        onCountChanged: if (currentIndex === -1 && count > 0) {
            currentIndex = 0;
        }
        clip: true

        ItemSelectionModel {
            id: mailSelectionModel
            model: mails.model
        }

        MailActions {
            id: mailActions
            selectionModel: mailSelectionModel
            mailApplication: MailApplication

            onMailSaveAs: (item) => {
                const component = Qt.createComponent("QtQuick.Dialogs", "FileDialog");
                const dialog = component.createObject(root.QQC2.Overlay.overlay, {
                    title: i18n("Save Message - Merkuro Mail"),
                    nameFilters: [i18n("Email messages (*.mbox)")],
                    currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation),
                    fileMode: FileDialog.SaveFile,
                });

                dialog.accepted.connect(() => {
                    if (dialog.selectedFile) {
                        MailManager.saveMail(dialog.selectedFile, item);
                    }
                });
                dialog.open();
            }

            onMoveToRequested: items => {
                const component = Qt.createComponent("org.kde.akonadi", "CollectionChooserPage");
                const page = root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                    configGroup: 'mail-collection-chooser-move',
                    title: i18nc("@title:dialog", "Move Selection To:"),
                    mimeTypeFilter: [Akonadi.MimeTypes.mail],
                });

                page.selected.connect((collection) => {
                    mailActions.moveTo(items, collection);
                    page.closeDialog();
                });
                page.rejected.connect(() => {
                    page.closeDialog();
                });
            }

            onCopyToRequested: items => {
                const component = Qt.createComponent("org.kde.akonadi", "CollectionChooserPage");
                const page = root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                    configGroup: 'mail-collection-chooser-move',
                    title: i18nc("@title:dialog", "Copy Selection To:"),
                    mimeTypeFilter: [Akonadi.MimeTypes.mail],
                });
                page.selected.connect((collection) => {
                    mailActions.copyTo(items, collection);
                    page.closeDialog();
                });
                page.rejected.connect(() => {
                    page.closeDialog();
                });
            }
        }

        Component {
            id: contextMenu
            Components.ConvergentContextMenu {
                Kirigami.Action {
                    text: i18nc("@action:menu", "Mark Message")

                    Kirigami.Action {
                        fromQAction: MailApplication.action('mark_read')
                    }

                    Kirigami.Action {
                        fromQAction: MailApplication.action('mark_unread')
                    }

                    Kirigami.Action {
                        separator: true
                    }

                    Kirigami.Action {
                        fromQAction: MailApplication.action('mark_important')
                    }
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_trash')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_move_to')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_copy_to')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_save_as')
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

        section {
            delegate: Kirigami.ListSectionHeader {
                required property string section
                label: section
            }
            property: "date"
        }

        onCurrentItemChanged: if (currentIndex !== -1 && currentItem) {
            mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(currentIndex, 0), ItemSelectionModel.Current);

            const pageStack = (root.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack;

            if (pageStack.depth === 2) {
                pageStack.lastItem.emptyItem = currentItem.item;
                pageStack.lastItem.mailActions = mailActions,
                pageStack.lastItem.props = {
                    from: currentItem.from,
                    to: currentItem.to,
                    sender: currentItem.sender,
                    item: currentItem.item,
                    title: currentItem.title,
                };
            } else {
                pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    emptyItem: currentItem.item,
                    mailActions: mailActions,
                    props: {
                        from: currentItem.from,
                        to: currentItem.to,
                        sender: currentItem.sender,
                        item: currentItem.item,
                        title: currentItem.title,
                    },
                });
                mails.forceActiveFocus();
            }

            if (!currentItem.status.isRead) {
                mailActions.setReadState(true);
            }
        }

        delegate: Item {
            id: parentDelegate

            required property date datetime
            required property string from
            required property string to
            required property string sender
            required property string title
            required property var status
            required property var item
            required property int index

            height: mailDelegate.implicitHeight

            MailDelegate {
                id: mailDelegate

                // Called from the sidebar when dropping
                function moveToCollection(collection: var): void {
                    const items = mailActions.selectionToItems();
                    mailActions.moveTo(items, collection);
                }

                listView: parentDelegate.ListView.view

                datetime: parentDelegate.datetime
                from: parentDelegate.from
                to: parentDelegate.to
                sender: parentDelegate.sender
                title: parentDelegate.title
                status: parentDelegate.status
                item: parentDelegate.item
                index: parentDelegate.index
                selectionModel: mailSelectionModel

                onOpenMailRequested: {
                    mails.currentIndex = index;
                }

                onStarMailRequested: {
                    mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mailDelegate.index, 0), ItemSelectionModel.Current);
                    mailActions.setImportantState(!status.isImportant);
                }

                onContextMenuRequested: {
                    mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mailDelegate.index, 0), ItemSelectionModel.Current);
                    mailActions.setActionState();

                    const menu = contextMenu.createObject(root);
                    root.collection = mailDelegate.item;
                    menu.popup();

                    menu.closed.connect(() => {
                        mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mails.currentIndex, 0), ItemSelectionModel.Current);
                    })
                }

                states: State {
                    when: mailDelegate.Drag.active
                    ParentChange {
                        target: mailDelegate
                        parent: root.QQC2.Overlay.overlay
                    }
                }

                DragHandler {
                    id: dragHandler

                    enabled: !Kirigami.Settings.isMobile
                    cursorShape: Qt.DragMoveCursor
                    onActiveChanged: if (!active) {
                        mailDelegate.Drag.drop();
                    } else {
                        mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(mailDelegate.index, 0), ItemSelectionModel.Current);
                    }
                }

                Drag.active: dragHandler.active
                Drag.hotSpot.x: mailDelegate.width / 2
                Drag.hotSpot.y: mailDelegate.height / 2
            }
        }
    }
}
