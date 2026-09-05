// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick

import org.kde.merkuro.mail
import org.kde.kirigami as Kirigami
import './private'

Kirigami.ScrollablePage {
    id: root

    required property var emptyItem
    required property MailActions mailActions
    required property MailPresentationModel folderModel

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.largeSpacing

    ConversationModel {
        id: conversationModel

        seedItem: root.emptyItem
        folderModel: root.folderModel
    }

    function positionAtAnchor(): void {
        // The model can be reset before ListView has updated its count and
        // laid out the new delegates. Defer the positioning until that work
        // has completed, otherwise the old position may be retained when the
        // viewer is reused for another seed message.
        Qt.callLater(() => {
            const anchorRow = conversationModel.anchorRow;
            if (!root.visible || anchorRow < 0 || conversationList.count <= anchorRow) {
                return;
            }

            if (conversationModel.anchorRow >= 0 && conversationList.count > conversationModel.anchorRow) {
                conversationList.forceLayout();
                conversationList.positionViewAtIndex(conversationModel.anchorRow, ListView.Beginning);
            }
        });
    }

    onVisibleChanged: if (visible) {
        Qt.callLater(() => root.positionAtAnchor());
    }

    actions: [
        Kirigami.Action {
            text: i18nc("@action", "Reply")
            icon.name: "mail-reply-sender-symbolic"
            onTriggered: mailActions.replyToSender(root.emptyItem)
        },
        Kirigami.Action {
            text: i18nc("@action", "Reply to All")
            icon.name: "mail-reply-all-symbolic"
            onTriggered: mailActions.replyToAll(root.emptyItem)
        },
        Kirigami.Action {
            text: i18nc("@action", "Forward")
            icon.name: "mail-forward-symbolic"
            onTriggered: mailActions.forward(root.emptyItem)
        },
        Kirigami.Action {
            fromQAction: MailApplication.action('mail_trash')
            onTriggered: {
                mailActions.item = root.emptyItem
                MailApplication.action("mail_trash").trigger();
                mailActions.item = undefined;
            }
        },
        Kirigami.Action {
            fromQAction: MailApplication.action('mail_delete')
            icon.color: Kirigami.Theme.negativeTextColor
            onTriggered: {
                mailActions.item = root.emptyItem
                MailApplication.action("mail_delete").trigger();
                mailActions.item = undefined;
            }
        }
    ]

    ListView {
        id: conversationList

        anchors.fill: parent
        model: conversationModel
        spacing: Kirigami.Units.smallSpacing
        clip: true
        reuseItems: false

        onCountChanged: root.positionAtAnchor()

        delegate: ThreadMessageCard {
            required property int itemId

            isSeed: itemId === root.emptyItem.id

            onContentLoadedChanged: if (contentLoaded && itemId === conversationModel.seedItem.id && ListView.view) {
                ListView.view.positionAtAnchor();
            }

            onImplicitHeightChanged: if (itemId === conversationModel.seedItem.id && ListView.view) {
                ListView.view.positionAtAnchor();
            }
        }

        Connections {
            target: conversationModel

            function onAnchorRowChanged(): void {
                root.positionAtAnchor();
            }

            function onModelReset(): void {
                root.positionAtAnchor();
            }
        }

        Component.onCompleted: root.positionAtAnchor()
    }
}
