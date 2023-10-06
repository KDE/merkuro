// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.merkuro.calendar 1.0 as Calendar
import "labelutils.js" as LabelUtils

Kirigami.ShadowedRectangle {
    id: root

    property bool isInDayGridView: false
    property bool isOpenOccurrence: false
    property bool reactToCurrentMonth: false
    property bool isInCurrentMonth: true
    property bool allDay: false

    required property bool hovered
    required property color incidenceColor

    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, root.incidenceColor, hovered || isOpenOccurrence ? 0.07 : 0.15)
    opacity: !isInDayGridView || isOpenOccurrence || (isInCurrentMonth && allDay) ? 1 : 0
    radius: Kirigami.Units.smallSpacing

    anchors.fill: parent

    shadow {
        size: Kirigami.Units.smallSpacing
        color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, root.incidenceColor, 0.4)
        yOffset: 2
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }
}
