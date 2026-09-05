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
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kitemmodels
import org.kde.merkuro.mail
import org.kde.merkuro.components
import './private'

Kirigami.ScrollablePage {
    id: root

    property var collection
    property alias searchString: searchModel.searchString
    property bool threadingModelRefreshPending: true

    title: searchString.length > 0 ? i18nc("@title", "Search: %1", searchString) : mailModel.folderName

    MailModel {
        id: mailModel

        collectionSelectionModel: MailManager.collectionSelectionModel
        entryTreeModel: MailManager.entryTreeModel
        threading: Config.threadedMessageView ? MessageListAggregation.PerfectReferencesAndSubject : MessageListAggregation.NoThreading
        onFolderNameChanged: {
            mails.currentIndex = -1
        }
    }

    SearchModel {
        id: searchModel
    }

    KDescendantsProxyModel {
        id: mailsModel

        model: root.searchString.length > 0 ? searchModel : mailModel
        expandsByDefault: false
    }

    Connections {
        target: mailModel

        function onModelReset(): void {
            root.threadingModelRefreshPending = true
        }

        function onLayoutChanged(): void {
            if (!root.threadingModelRefreshPending) {
                return
            }

            root.threadingModelRefreshPending = false
            if (root.searchString.length > 0) {
                return
            }

            // MessageModel reloads with its UI disconnected and reports the
            // completed fill through layoutChanged(). Rebind the descendants
            // proxy so it rebuilds its mapping for the new hierarchy.
            mailsModel.model = null
            mailsModel.model = mailModel
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
            visible: root.searchString.length === 0
        },
        Kirigami.Action {
            text: i18nc("@action", "Thread Messages")
            tooltip: i18nc("@tooltip", "Toggle threaded message view")
            icon.name: "view-list-tree"
            checkable: true
            checked: Config.threadedMessageView
            visible: root.searchString.length === 0
            onTriggered: {
                root.threadingModelRefreshPending = true
                Config.threadedMessageView = !Config.threadedMessageView
                Config.save()
            }
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
        model: mailsModel
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

            onMailRescheduleRequested: (item) => {
                const dialog = rescheduleDialog.createObject(root, { item });
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

            onComposerRequested: (to, subject, body) => {
                root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(Qt.resolvedUrl("./MailComposer.qml"), {
                    initialTo: to,
                    initialSubject: subject,
                    initialBody: body,
                });
            }
        }

        Component {
            id: rescheduleDialog
            FormCard.FormCardDialog {
                id: dialogRoot

                property var item

                title: i18nc("@title:dialog", "Reschedule Message")
                standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Ok

                onAccepted: MailManager.rescheduleMail(dialogRoot.item, dateTimeDelegate.value)
                onClosed: dialogRoot.destroy()

                FormCard.FormDateTimeDelegate {
                    id: dateTimeDelegate
                    text: i18nc("@label", "Send Date and Time")
                }
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
                    fromQAction: MailApplication.action('send_now')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_reschedule')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_reply')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_reply_all')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_forward')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action('mail_trash')
                }

                Kirigami.Action {
                    fromQAction: MailApplication.action("mail_delete")
                    icon.color: Kirigami.Theme.negativeTextColor
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
            property: "threadSectionDate"
        }

        onCurrentItemChanged: if (currentIndex !== -1 && currentItem) {
            mailSelectionModel.setCurrentIndex(mailSelectionModel.model.index(currentIndex, 0), ItemSelectionModel.Current);

            const pageStack = (root.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack;

            if (pageStack.depth === 2) {
                pageStack.lastItem.emptyItem = currentItem.item;
                pageStack.lastItem.mailActions = mailActions,
                pageStack.lastItem.title = currentItem.title;
                Qt.callLater(() => pageStack.lastItem.positionAtAnchor());
            } else {
                pageStack.push(Qt.resolvedUrl('ConversationViewer.qml'), {
                    emptyItem: currentItem.item,
                    mailActions: mailActions,
                    folderModel: mailModel,
                    title: currentItem.title,
                });
                Qt.callLater(() => pageStack.lastItem.positionAtAnchor());
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
            required property var dispatchMode
            required property int unreadDescendantCount
            required property var threadSenders
            required property int index
            required property int kDescendantLevel
            required property var kDescendantHasSiblings
            required property bool kDescendantExpandable
            required property bool kDescendantExpanded

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
                dispatchMode: parentDelegate.dispatchMode
                unreadDescendantCount: parentDelegate.unreadDescendantCount
                threadSenders: parentDelegate.threadSenders
                index: parentDelegate.index
                level: parentDelegate.kDescendantLevel
                treeModel: mailsModel
                hasSiblings: parentDelegate.kDescendantHasSiblings
                expandable: parentDelegate.kDescendantExpandable
                expanded: parentDelegate.kDescendantExpanded
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
