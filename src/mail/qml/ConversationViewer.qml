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

        delegate: ThreadMessageCard {
            required property int itemId

            isSeed: itemId === root.emptyItem.id
        }

        Connections {
            target: conversationModel

            function onAnchorRowChanged(): void {
                if (conversationModel.anchorRow >= 0) {
                    conversationList.positionViewAtIndex(conversationModel.anchorRow, ListView.Beginning)
                }
            }
        }

        Component.onCompleted: Qt.callLater(() => {
            if (conversationModel.anchorRow >= 0) {
                conversationList.positionViewAtIndex(conversationModel.anchorRow, ListView.Beginning)
            }
        })
    }
}
