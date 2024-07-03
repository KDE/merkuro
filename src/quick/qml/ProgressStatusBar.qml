// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.akonadi as Akonadi
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

RowLayout {
    id: root

    readonly property alias working: progressModel.working
    readonly property bool popupOpen: popupLoader.active && popupLoader.item.visible
    
    property int popupMaxHeight: 300

    onVisibleChanged: if (!visible) popupLoader.active = false

    Akonadi.ProgressModel {
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

            readonly property point rootPoint: mapFromItem(root, root.x, root.y)
            readonly property int listViewTopMargin: Kirigami.Units.largeSpacing
            readonly property int listViewBottomMargin: Kirigami.Units.largeSpacing
            readonly property int scrollInternalHeight:
                contentItem.contentHeight + listViewTopMargin + listViewBottomMargin

            x: rootPoint.x
            y: rootPoint.y - height
            width: root.width
            height: Math.min(scrollInternalHeight, root.popupMaxHeight)
            padding: 0

            contentItem: QQC2.ScrollView {
                ListView {
                    topMargin: progressPopup.listViewTopMargin
                    bottomMargin: progressPopup.listViewBottomMargin
                    spacing: Kirigami.Units.largeSpacing

                    model: progressModel
                    delegate: ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing

                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: model.display
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: model.status
                            wrapMode: Text.Wrap
                        }
                        RowLayout {
                            spacing: 0

                            QQC2.ProgressBar {
                                Layout.fillWidth: true
                                id: itemProgressBar
                                from: 0
                                to: 100
                                value: model.progress
                                indeterminate: model.usesBusyIndicator
                            }
                            QQC2.Button {
                                Layout.maximumHeight: itemProgressBar.implicitHeight
                                display: QQC2.AbstractButton.IconOnly
                                flat: true
                                text: i18n("Cancel")
                                icon.name: "process-stop"
                                visible: model.canBeCancelled
                                onClicked: progressModel.cancelItem(model.id)
                            }
                        }
                    }
                }
            }
        }
        onLoaded: item.open()
    }
}