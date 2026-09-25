// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.mail as Mail
import org.kde.ki18n

RowLayout {
    id: root

    readonly property alias working: progressModel.working
    readonly property QQC2.Popup progressPopup: popupLoader.item as QQC2.Popup
    readonly property bool popupOpen: popupLoader.active && root.progressPopup.visible
    
    property int popupMaxHeight: 300

    onVisibleChanged: if (!visible) popupLoader.active = false

    Mail.ProgressModel {
        id: progressModel
        onShowProgressView: popupLoader.active = true
    }

    QQC2.ProgressBar {
        id: progressBar

        Layout.fillWidth: true

        from: 0
        to: 100
        value: progressModel.progress
        indeterminate: progressModel.indeterminate
    }

    QQC2.Button {
        Layout.maximumHeight: progressBar.implicitHeight
        display: QQC2.AbstractButton.IconOnly
        icon.name: root.popupOpen ? "usermenu-down" : "usermenu-up"
        visible: progressModel.working
        onClicked: popupLoader.active = !popupLoader.active
    }

    Loader {
        id: popupLoader

        active: false
        sourceComponent: QQC2.Popup {
            id: progressPopup

            readonly property point rootPoint: root.mapToItem(progressPopup.parent, 0, 0)
            readonly property int listViewTopMargin: Kirigami.Units.largeSpacing
            readonly property int listViewBottomMargin: Kirigami.Units.largeSpacing
            readonly property int scrollInternalHeight:
                ((progressPopup.contentItem as QQC2.ScrollView).contentItem as ListView).contentHeight + listViewTopMargin + listViewBottomMargin

            x: rootPoint.x
            y: rootPoint.y - height
            width: root.width
            height: Math.min(scrollInternalHeight, root.popupMaxHeight)
            padding: 0

            contentItem: QQC2.ScrollView {
                ListView {
                    id: progressList
                    topMargin: progressPopup.listViewTopMargin
                    bottomMargin: progressPopup.listViewBottomMargin
                    spacing: Kirigami.Units.largeSpacing

                    model: progressModel
                    delegate: ColumnLayout {
                        id: progressDelegate

                        required property string display
                        required property string status
                        required property real progress
                        required property bool usesBusyIndicator
                        required property bool canBeCancelled
                        required property string itemId

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing

                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: progressDelegate.display
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: progressDelegate.status
                            wrapMode: Text.Wrap
                        }
                        RowLayout {
                            spacing: 0

                            QQC2.ProgressBar {
                                Layout.fillWidth: true
                                id: itemProgressBar
                                from: 0
                                to: 100
                                value: progressDelegate.progress
                                indeterminate: progressDelegate.usesBusyIndicator
                            }
                            QQC2.Button {
                                Layout.maximumHeight: itemProgressBar.implicitHeight
                                display: QQC2.AbstractButton.IconOnly
                                flat: true
                                text: KI18n.i18n("Cancel")
                                icon.name: "process-stop"
                                visible: progressDelegate.canBeCancelled
                                onClicked: progressModel.cancelItem(progressDelegate.itemId)
                            }
                        }
                    }
                }
            }
        }
        onLoaded: root.progressPopup.open()
    }
}
