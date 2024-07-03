// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2016 Michael Bohlender <michael.bohlender@kdemail.net>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2

QQC2.AbstractButton {
    id: root

    property string name
    property string type
    property alias actionIcon: actionButton.icon.name
    property alias actionTooltip: actionButton.text
    signal execute;
    signal publicKeyImport;

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    background: Rectangle {
        id: background
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.disabledTextColor
        radius: 3
    }

    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing
    contentItem: RowLayout {
        id: content
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            color: Kirigami.Theme.backgroundColor
            Layout.preferredHeight: Kirigami.Units.gridUnit
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                height: Kirigami.Units.gridUnit
                width: Kirigami.Units.gridUnit
                source: root.icon.name
            }
        }
        QQC2.Label {
            text: root.name
        }
        QQC2.ToolButton {
            visible: root.type === "application/pgp-keys"
            icon.name: 'gpg'
            onClicked: root.publicKeyImport()

            text: i18nc("@action:button", "Import key")
            display: QQC2.ToolButton.IconOnly

            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: text
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        QQC2.ToolButton {
            id: actionButton
            onClicked: root.execute()
            display: QQC2.ToolButton.IconOnly
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: text
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
