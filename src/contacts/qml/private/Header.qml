/*
 * SPDX-FileCopyrightText: 2019 Fabian Riethmayer <fabian@web2.0-apps.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import Qt5Compat.GraphicalEffects as GE
import org.kde.kirigamiaddons.labs.components 1.0 as KAComponents

Control {
    id: root

    required property var source
    required property string name

    bottomPadding: strip.children.length > 0 ? strip.height : 0
    clip: true

    // Container for the content of the header
    contentItem: Kirigami.FlexColumn {
        id: contentContainer

        maximumWidth: Kirigami.Units.gridUnit * 30

        RowLayout {
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit

            KAComponents.Avatar {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                name: root.name
                visible: !root.source
            }

            Kirigami.Icon {
                id: imageIcon

                Layout.fillHeight: true
                Layout.preferredWidth: height

                source: root.source
                visible: root.source

                layer {
                    enabled: root.source
                    effect: GE.OpacityMask {
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

            Kirigami.Heading {
                text: root.name
                Layout.alignment: Qt.AlignBottom
            }
        }
    }
}
