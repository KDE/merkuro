// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.merkuro.mail
import org.kde.kirigami as Kirigami
import org.kde.pim.mimetreeparser as MimeTreeParser
import org.kde.ki18n

// External KMime shared-pointer metadata is not available to qmllint.
// qmllint disable unresolved-type missing-type
MimeTreeParser.MailViewer {
    id: root

    property var emptyItem
    property var props
    required property MailActions mailActions
    property real itemId: 0
    readonly property var actionItem: root.itemId > 0 ? messageLoader.item : root.emptyItem
    readonly property bool hasDistinctSender: root.sender.length > 0 && root.sender !== root.from
    readonly property bool hasLoadedItem: root.itemId <= 0 || Boolean(root.message)

    Component.onDestruction: if (root.itemId > 0 && root.mailActions) root.mailActions.item = undefined

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    icalCustomComponent: Qt.resolvedUrl("./mailpartview/ICalPart.qml")

    actions: [
        Kirigami.Action {
            text: KI18n.i18nc("@action", "Reply")
            icon.name: "mail-reply-sender-symbolic"
            enabled: root.hasLoadedItem
            onTriggered: root.mailActions.replyToSender(root.actionItem)
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action", "Reply to All")
            icon.name: "mail-reply-all-symbolic"
            enabled: root.hasLoadedItem
            onTriggered: root.mailActions.replyToAll(root.actionItem)
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action", "Forward")
            icon.name: "mail-forward-symbolic"
            enabled: root.hasLoadedItem
            onTriggered: root.mailActions.forward(root.actionItem)
        },
        Kirigami.Action {
            fromQAction: MailApplication.action('mail_trash')
            enabled: root.hasLoadedItem && MailApplication.action('mail_trash').enabled
            onTriggered: {
                root.mailActions.item = root.actionItem
                MailApplication.action("mail_trash").trigger();
                if (root.itemId <= 0) root.mailActions.item = undefined;
            }
        },
        Kirigami.Action {
            fromQAction: MailApplication.action('mail_delete')
            icon.color: Kirigami.Theme.negativeTextColor
            enabled: root.hasLoadedItem && MailApplication.action('mail_delete').enabled
            onTriggered: {
                root.mailActions.item = root.actionItem
                MailApplication.action("mail_delete").trigger();
                if (root.itemId <= 0) root.mailActions.item = undefined;
            }
        }
    ]

    component AddressRow: RowLayout {
        id: addressRow

        required property string address
        required property bool showDkim

        readonly property bool hasDkimStatus: addressRow.showDkim && dkimVerifier.status !== DkimVerifier.Unknown
        readonly property string dkimText: hasDkimStatus ? KI18n.i18nc("@info", "Domain authentication (DKIM): %1", statusText()) : ""

        visible: addressRow.address.length > 0
        spacing: Kirigami.Units.smallSpacing

        Layout.fillWidth: true

        QQC2.ToolTip.visible: hasDkimStatus && addressHover.hovered
        QQC2.ToolTip.text: dkimText
	QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

        HoverHandler {
            id: addressHover
        }

        Kirigami.Icon {
            visible: addressRow.hasDkimStatus
            source: "emblem-information"
            color: Kirigami.Theme.textColor
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Accessible.ignored: true
        }

        QQC2.Label {
            text: addressRow.address
            elide: Text.ElideRight
            Layout.fillWidth: true
            Accessible.description: addressRow.dkimText
        }

        function statusText(): string {
            switch (dkimVerifier.status) {
            case DkimVerifier.Valid:
                return dkimVerifier.hasWarning
                    ? KI18n.i18nc("@info", "Valid signature with warnings from domain %1", dkimVerifier.signingDomain)
                    : KI18n.i18nc("@info", "Valid signature from domain %1", dkimVerifier.signingDomain);
            case DkimVerifier.Invalid:
                return KI18n.i18nc("@info", "Invalid domain signature");
            case DkimVerifier.EmailNotSigned:
                return KI18n.i18nc("@info", "No domain signature");
            case DkimVerifier.NeedToBeSigned:
                return KI18n.i18nc("@info", "Expected signature from domain %1", dkimVerifier.signingDomain);
            default:
                return "";
            }
        }
    }

    header: ColumnLayout {
        width: parent.width
        spacing: 0

        QQC2.Pane {
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            Layout.fillWidth: true
            padding: root.padding
            horizontalPadding: Kirigami.Units.gridUnit

            contentItem: Kirigami.Heading {
                text: root.props && root.props.title ? root.props.title : root.subject
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }
        }

        QQC2.ToolBar {
            id: mailHeader

            Layout.fillWidth: true

            padding: root.padding
            horizontalPadding: Kirigami.Units.gridUnit
            visible: root.from.length > 0 || root.to.length > 0 || root.subject.length > 0 

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            background: Rectangle {
                color: Kirigami.Theme.alternateBackgroundColor

                Kirigami.Separator {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                }

                Kirigami.Separator {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }

            contentItem: GridLayout {
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                columns: 2

                QQC2.Label {
                    text: KI18n.i18n('Date:')
                    font.bold: true
                    visible: date.text.length > 0

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    id: date
                    text: root.dateTime.toLocaleString(Qt.locale(), Locale.ShortFormat)
                    visible: text.length > 0
                    horizontalAlignment: Text.AlignRight
                }

                QQC2.Label {
                    text: KI18n.i18n('From:')
                    font.bold: true
                    visible: root.from.length > 0

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                AddressRow {
                    address: root.from
                    showDkim: !root.hasDistinctSender
                }

                QQC2.Label {
                    text: KI18n.i18n('Sender:')
                    font.bold: true
                    visible: root.hasDistinctSender

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                AddressRow {
                    visible: root.hasDistinctSender
                    address: root.sender
                    showDkim: true
                }

                QQC2.Label {
                    text: KI18n.i18n('To:')
                    font.bold: true
                    visible: root.to.length > 0

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    text: root.to
                    elide: Text.ElideRight
                    visible: root.to.length > 0

                    Layout.fillWidth: true
                }
            }
        }
    }

    DkimVerifier {
        id: dkimVerifier
        message: root.message
    }

    MessageLoader {
        id: messageLoader
        onMessageChanged: {
            root.message = message
            if (root.itemId > 0) root.mailActions.item = message ? item : undefined
        }
    }

    Binding {
        target: messageLoader
        property: root.itemId > 0 ? "itemId" : "item"
        value: root.itemId > 0 ? root.itemId : root.emptyItem
        when: root.itemId > 0 || root.emptyItem !== undefined
    }
}
// qmllint enable unresolved-type missing-type
