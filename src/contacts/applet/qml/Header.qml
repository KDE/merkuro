/*
 * SPDX-FileCopyrightText: 2019 Fabian Riethmayer <fabian@web2.0-apps.de>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigamiaddons.components
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

Control {
    id: root
    clip: true
    default property alias contentItems: content.children

    required property string photoUrl
    required property string name
    property var backgroundSource

    background: Item {
        // Background image
        Image {
            id: bg
            width: root.width
            height: root.height
            source: root.backgroundSource
        }

        FastBlur {
            id: blur
            source: bg
            radius: 48
            width: root.width
            height: root.height
        }
        ColorOverlay {
            width: root.width
            height: root.height
            source: blur
            color: "#66808080"
        }
        Rectangle {
            id: strip
            color: "#66F0F0F0"
            anchors.bottom: parent.bottom;
            height: 2 * Kirigami.Units.gridUnit
            width: parent.width
            visible: children.length > 0
        }
    }
    bottomPadding: strip.children.length > 0 ? strip.height : 0

    // Container for the content of the header
    contentItem: Kirigami.FlexColumn {
        id: contentContainer

        maximumWidth: Kirigami.Units.gridUnit * 30

        RowLayout {
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.gridUnit
            Layout.bottomMargin: Kirigami.Units.gridUnit

            Avatar {
                name: root.name
                source: root.photoUrl
                Layout.fillHeight: true
                Layout.preferredWidth: height
            }
            ColumnLayout {
                id: content
                Layout.alignment: Qt.AlignBottom
                Layout.leftMargin: Kirigami.Units.gridUnit
            }
        }
    }
}
