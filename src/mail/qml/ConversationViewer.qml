// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-FileCopyrightText: 2022 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.merkuro.mail 1.0
import org.kde.kirigami 2.14 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.pim.mimetreeparser 1.0 as MimeTreeParser

import './mailpartview'

MimeTreeParser.MailViewer {
    id: root

    required property var emptyItem
    required property var props

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contextualActions: [
        Kirigami.Action {
            text: i18n("Move to trash")
            iconName: "albumfolder-user-trash"
            onTriggered: {
                MailManager.moveToTrash(root.item);
                applicationWindow().pageStack.pop();
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
            visible: root.from.length > 0 || root.to.length > 0 || root.subject.length > 0 

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            background: Item {
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.alternateBackgroundColor
                }

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
