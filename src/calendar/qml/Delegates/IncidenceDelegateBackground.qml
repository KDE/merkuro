// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import "labelutils.js" as LabelUtils

Kirigami.ShadowedRectangle {
    id: incidenceDelegateBackground

    property bool isInDayGridView: false
    property bool isOpenOccurrence: false
    property bool reactToCurrentMonth: false
    property bool isInCurrentMonth: true
    property bool isDark: CalendarUiUtils.darkMode
    property bool allDay: false
    
    anchors.fill: parent
    color: isOpenOccurrence ? modelData.color :
        LabelUtils.getIncidenceDelegateBackgroundColor(modelData.color, root.isDark, modelData.endTime, Calendar.Config.pastEventsTransparencyLevel)
    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    opacity: !isInDayGridView || isOpenOccurrence || (isInCurrentMonth && allDay) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

    radius: Kirigami.Units.smallSpacing

    shadow.size: Kirigami.Units.largeSpacing
    shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
    shadow.yOffset: 2

    border.width: 1
    border.color: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)
}
