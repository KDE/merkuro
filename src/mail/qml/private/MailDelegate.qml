// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.delegates 1.0 as Delegates
import org.kde.kirigamiaddons.labs.components 1.0 as Components

Delegates.IndicatorItemDelegate {
    id: root

    required property date datetime
    required property string from
    required property string to
    required property string sender
    required property string title
    required property var status
    required property var item

    readonly property string datetimeText: datetime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)

    unread: status && !status.isRead

    signal openMailRequested()
    signal starMailRequested()
    signal contextMenuRequested()

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.contextMenuRequested()
    }

    onPressAndHold: root.contextMenuRequested()
    onClicked: root.openMailRequested()

    contentItem: RowLayout {
        Components.Avatar {
            // Euristic to extract name from "Name <email>" pattern
            name: root.from.replace(/<.*>/, '').replace(/\(.*\)/, '')
            // Extract and use email address as unique identifier for image provider
            source: 'image://contact/' + new RegExp("<(.*)>").exec(root.from)[1] ?? ''
            Layout.rightMargin: Kirigami.Units.largeSpacing
            sourceSize.width: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            sourceSize.height: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            Layout.preferredWidth: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.from
                    elide: Text.ElideRight
                    font.weight: root.unread ? Font.Bold : Font.Normal
                }

                QQC2.Label {
                    color: Kirigami.Theme.disabledTextColor
                    text: root.datetimeText
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.weight: root.unread ? Font.Bold : Font.Normal
            }
        }
    }
}

