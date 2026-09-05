// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.merkuro.mail
import org.kde.pim.mimetreeparser as MimeTreeParser

Item {
    id: root

    required property var item
    required property string title
    required property string from
    required property string sender
    required property string to
    required property date datetime
    required property bool isSeed

    property bool expanded: true
    readonly property bool contentLoaded: !!messageLoader.message || messageLoader.errorString.length > 0

    width: ListView.view ? ListView.view.width : parent.width
    implicitHeight: cardLayout.implicitHeight

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.disabledTextColor
        border.width: 1
        radius: Kirigami.Units.smallSpacing
    }

    ColumnLayout {
        id: cardLayout

        width: parent.width
        spacing: 0

        QQC2.ToolBar {
            Layout.fillWidth: true
            padding: Kirigami.Units.largeSpacing

            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            background: Rectangle {
                color: root.isSeed ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor
            }

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    QQC2.Label {
                        text: root.from || root.sender || i18n("Unknown sender")
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: root.to
                        visible: text.length > 0
                        elide: Text.ElideRight
                        opacity: 0.8
                        Layout.fillWidth: true
                    }
                }

                QQC2.Label {
                    text: root.datetime.toLocaleString(Qt.locale(), Locale.ShortFormat)
                    visible: root.datetime && root.datetime.getTime() > 0
                    opacity: 0.8
                }

                QQC2.ToolButton {
                    icon.name: root.expanded ? "arrow-up" : "arrow-down"
                    text: root.expanded ? i18n("Collapse message") : i18n("Expand message")
                    display: QQC2.AbstractButton.IconOnly
                    onClicked: root.expanded = !root.expanded
                }
            }
        }

        QQC2.Label {
            text: root.title
            visible: text.length > 0
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
            font.bold: true
        }

        MimeTreeParser.MailViewer {
            id: messageViewer

            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded && messageLoader.message ? implicitHeight : 0
            visible: root.expanded && messageLoader.message
            header: null
            footer: null
            padding: Kirigami.Units.largeSpacing
            icalCustomComponent: Qt.resolvedUrl("../mailpartview/ICalPart.qml")
            message: messageLoader.message
            flickable.interactive: false
        }

        QQC2.BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: root.expanded && messageLoader.loading
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            visible: root.expanded && messageLoader.errorString.length > 0
            text: messageLoader.errorString
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
        }
    }

    MessageLoader {
        id: messageLoader
        item: root.item
    }
}
