/*
    SPDX-FileCopyrightText: 2014-2015 David Rosca <nowrep@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import org.kde.plasma.plasmoid 2.0
import QtQuick 2.2
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

MouseArea {
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    acceptedButtons: Qt.LeftButton

    onClicked: Plasmoid.expanded = !Plasmoid.expanded;

    hoverEnabled: true
}
