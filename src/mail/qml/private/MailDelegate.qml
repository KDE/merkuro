// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQml.Models

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components

import org.kde.merkuro.components

Delegates.IndicatorItemDelegate {
    id: root

    required property date datetime
    required property string from
    required property string to
    required property string sender
    required property string title
    required property var status
    required property var item
    required property ItemSelectionModel selectionModel

    readonly property string datetimeText: datetime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)

    unread: status && !status.isRead

    signal openMailRequested()
    signal starMailRequested()
    signal contextMenuRequested()

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.contextMenuRequested()
    }

    onClicked: if (root.selectionModel.hasSelection) {
        root.selectionModel.select(root.selectionModel.model.index(root.index, 0), ItemSelectionModel.Toggle)
    } else {
        root.openMailRequested()
    }
    onPressAndHold: {
        root.selectionModel.clearCurrentIndex();
        root.selectionModel.select(root.selectionModel.model.index(root.index, 0), ItemSelectionModel.Toggle);
    }

    Connections {
        target: root.selectionModel
        function onSelectionChanged(selected, deselected) {
            checkbox.checked = root.selectionModel.isRowSelected(root.index);
        }
    }

    highlighted: root.selectionModel.currentIndex.row === root.index || checkbox.checked

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        ColoredCheckbox {
            id: checkbox
            visible: root.selectionModel.hasSelection
            checked: checked = root.selectionModel.isRowSelected(root.index);
            onToggled: root.selectionModel.select(root.selectionModel.model.index(root.index, 0), ItemSelectionModel.Toggle)

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

        Components.Avatar {
            // Heuristic to extract name from "Name <email>" pattern
            name: root.from.replace(/<.*>/, '').replace(/\(.*\)/, '')
            visible: !root.selectionModel.hasSelection
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
                spacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.from
                    elide: Text.ElideRight
                    font.weight: root.unread ? Font.Bold : Font.Normal
                }

                QQC2.AbstractButton {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    visible: root.status.isImportant
                    enabled: !root.selectionModel.hasSelection

                    contentItem: Kirigami.Icon {
                        source: root.status.isImportant ? 'favorite-favorited-symbolic' : 'favorite-symbolic'
                        color: root.status.isImportant ? 'yellow' : Kirigami.Theme.textColor
                        isMask: root.status.isImportant
                    }
                    onClicked: root.starMailRequested()
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

