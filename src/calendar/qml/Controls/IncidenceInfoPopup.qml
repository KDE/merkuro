// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.merkuro.calendar

QQC2.Popup {
    id: root

    property var incidenceData

    padding: 0
    clip: false

    background: Kirigami.ShadowedRectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View

        color: Kirigami.Theme.backgroundColor
        radius: Kirigami.Units.largeSpacing

        shadow.size: Kirigami.Units.largeSpacing
        shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
        shadow.yOffset: 2

        border.width: 1
        border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
    }

    contentItem: Loader {
        id: incidenceInfoContentsLoader

        anchors.fill: parent
        active: root.visible && root.incidenceData !== null && root.incidenceData !== undefined
        sourceComponent: IncidenceInfoContents {
            id: incidenceInfoContents

            anchors.fill: parent
            contentPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

            clip: true
            incidenceData: root.incidenceData
        }
    }
}
