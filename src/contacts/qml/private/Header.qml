/*
 * SPDX-FileCopyrightText: 2019 Fabian Riethmayer <fabian@web2.0-apps.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components

QQC2.Control {
    id: root

    required property var source
    required property string name
    property alias actions: toolbar.actions

    readonly property bool largeScreen: width > Kirigami.Units.gridUnit * 25
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.2)

    background: Item {
        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: avatar.color
                opacity: 0.2

            }
            Kirigami.Icon {
                visible: source
                scale: 1.8
                anchors.fill: parent

                source: root.source

                implicitWidth: 512
                implicitHeight: 512
            }

            layer.enabled: true
            layer.effect: HueSaturation {
                cached: true

                saturation: 1.9

                layer {
                    enabled: true
                    effect: FastBlur {
                        cached: true
                        radius: 100
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: -1.0; color: "transparent" }
                GradientStop { position: 1.0; color: Kirigami.Theme.backgroundColor }
            }
        }
    }

    contentItem: RowLayout {
        RowLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            Kirigami.ShadowedRectangle {
                Layout.margins: root.largeScreen ? Kirigami.Units.gridUnit * 2 : Kirigami.Units.largeSpacing
                Layout.preferredWidth: root.largeScreen ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 3
                Layout.preferredHeight: root.largeScreen ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 3

                radius: width
                color: Kirigami.Theme.backgroundColor

                shadow {
                    size: Kirigami.Units.gridUnit
                    xOffset: Kirigami.Units.smallSpacing
                    yOffset: Kirigami.Units.smallSpacing
                    color: root.shadowColor
                }

                Components.Avatar {
                    id: avatar

                    anchors.fill: parent

                    visible: !imageIcon.visible
                    name: root.name
                    imageMode: Components.Avatar.ImageMode.AdaptiveImageOrInitals
                }

                Kirigami.Icon {
                    id: imageIcon

                    anchors.fill: parent

                    source: root.source
                    roundToIconSize: false
                    visible: source

                    layer {
                        enabled: imageIcon.visible
                        effect: OpacityMask {
                            maskSource: Rectangle {
                                width: imageIcon.width
                                height: imageIcon.width
                                radius: imageIcon.width
                                color: "black"
                                visible: false
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                Layout.fillWidth: true

                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: root.name
                    font.bold: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                Kirigami.ActionToolBar {
                    Layout.fillWidth: true

                    id: toolbar
                }
            }
        }
    }
}
