// SPDX-FileCopyrightText: 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.merkuro.calendar

Row {
    id: root
    property date startDate
    property real dayWidth
    property real daysToShow
    property Component delegate

    height: childrenRect.height

    spacing: 0
    Repeater {
        model: root.daysToShow
        delegate: Loader {
            width: root.dayWidth
            property date day: DateUtils.addDaysToDate(root.startDate, modelData)
            sourceComponent: root.delegate
        }
    }
}

