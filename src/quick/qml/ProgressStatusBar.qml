// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.akonadi as Akonadi
import org.kde.kirigamiaddons.delegates 1.0 as Delegates

RowLayout {
    id: root

    readonly property alias working: progressModel.working
    readonly property bool popupOpen: popupLoader.active && popupLoader.item.visible
    
    property int popupMaxHeight: 300

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
            readonly property point rootPoint: mapFromItem(root, root.x, root.y)

            x: rootPoint.x
            y: rootPoint.y - height
            width: root.width
            height: Math.min(contentItem.contentHeight, root.popupMaxHeight)
            padding: 0

            contentItem: QQC2.ScrollView {
                ListView {
                    model: progressModel
                    delegate: ColumnLayout {

                        QQC2.Label {
                            text: model.display
                        }
                        RowLayout {
                            QQC2.ProgressBar {
                                from: 0
                                to: 100
                                value: model.progress
                            }
                        }
                    }
                }
            }
        }
        onLoaded: item.open()
    }
}