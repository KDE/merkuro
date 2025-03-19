// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

DayGridView {
    id: dayView

    objectName: "monthView"

    weekHeaderDelegate: QQC2.Label {
        padding: Kirigami.Units.smallSpacing
        verticalAlignment: Qt.AlignTop
        horizontalAlignment: Qt.AlignHCenter
        text: Calendar.Utils.weekNumber(startDate)
        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor
        }
    }
}
