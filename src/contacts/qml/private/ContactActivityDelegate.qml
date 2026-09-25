// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.AbstractFormDelegate {
    id: root

    required property string title
    required property string date
    required property string person
    required property string email
    required property int kind
    required property bool unread

    signal activated()

    text: title
    background.visible: root.kind !== ContactActivityModel.Events
    Accessible.description: [person, date].filter(part => part.length > 0).join(", ")
    onClicked: if (root.kind === ContactActivityModel.Messages) root.activated()

    Rectangle {
        objectName: "unreadIndicator"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        width: 4
        z: 1
        visible: root.unread
        color: Kirigami.Theme.highlightColor
        Accessible.ignored: true
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Components.Avatar {
            visible: root.email.length > 0
            name: root.person
            source: "image://contact/" + root.email
            sourceSize.width: Kirigami.Units.gridUnit * 2
            sourceSize.height: Kirigami.Units.gridUnit * 2
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Accessible.ignored: true
        }

        Kirigami.Icon {
            visible: root.email.length === 0
            source: root.kind === ContactActivityModel.Events ? "view-calendar-symbolic" : "mail-message-symbolic"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Accessible.ignored: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.person.length > 0 ? root.person : (root.kind === ContactActivityModel.Events ? KI18n.i18nc("@info:label", "Event") : KI18n.i18nc("@info:label", "Email"))
                    elide: Text.ElideRight
                    font.weight: root.unread ? Font.Bold : Font.Normal
                    Accessible.ignored: true
                }

                QQC2.Label {
                    text: root.date
                    color: Kirigami.Theme.disabledTextColor
                    Accessible.ignored: true
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.weight: root.unread ? Font.Bold : Font.Normal
                Accessible.ignored: true
            }
        }
    }
}
