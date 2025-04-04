// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.merkuro.mail
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.pim.mimetreeparser as MimeTreeParser
import './actions' as Actions

MimeTreeParser.MailViewer {
    id: root

    required property var emptyItem
    required property var props
    required property MailActions mailActions

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    icalCustomComponent: Qt.resolvedUrl("./mailpartview/ICalPart.qml")

    actions: [
        Kirigami.Action {
            text: i18nc("@action", "Move to Trash")
            icon.name: "albumfolder-user-trash-symbolic"
            onTriggered: {
                mailActions.item = root.item
                MailApplication.action('mail_trash').trigger();
                mailActions.item = undefined;
            }
        }
    ]

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
                text: props.title
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
                    text: i18n('Date:')
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
                    text: i18n('From:')
                    font.bold: true
                    visible: root.from.length > 0

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    text: root.from
                    visible: text.length > 0
                    elide: Text.ElideRight

                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: i18n('Sender:')
                    font.bold: true
                    visible: root.sender.length > 0 && root.sender !== root.from

                    Layout.rightMargin: Kirigami.Units.largeSpacing
                }

                QQC2.Label {
                    visible: root.sender.length > 0 && root.sender !== root.from
                    text: root.sender
                    elide: Text.ElideRight

                    Layout.fillWidth: true
                }

                QQC2.Label {
                    text: i18n('To:')
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

    MessageLoader {
        id: messageLoader

        item: root.emptyItem
        onMessageChanged: root.message = message
    }
}
