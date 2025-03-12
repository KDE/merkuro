// SPDX-FileCopyrightText: 2025 Shubham Shinde <shubshinde8381@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

Row {
    id: root

    required property date startDate
    required property int daysToShow
    required property bool showHolidaysConfig
    property bool hasHolidayInWeek: false

    property real dayWidth: 0
    property real hourLabelWidth: 0
    property real scrollbarWidth: 0

    width: parent.width
    spacing: 1
    visible: root.hasHolidayInWeek && root.showHolidaysConfig

    function checkHolidays(): void {
        let hasHoliday = false;
        for (let i = 0; i < root.daysToShow; ++i) {
            const date = Calendar.Utils.addDaysToDate(root.startDate, i);
            const formatedDate = Qt.formatDate(date, 'yyyy-MM-dd')
            if (formatedDate in Calendar.HolidayModel.holidays) {
                hasHoliday = true
                break;
            }
        }
        root.hasHolidayInWeek = hasHoliday;
    }

    QQC2.Label {
        width: root.hourLabelWidth
        height: parent.height
        padding: Kirigami.Units.smallSpacing
        leftPadding: Kirigami.Units.largeSpacing
        verticalAlignment: Text.AlignTop
        horizontalAlignment: Text.AlignRight
        text: i18n("Holidays")
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.disabledTextColor
    }

    Repeater {
        model: root.visible ? root.daysToShow : 0

        delegate: Rectangle {
            id: delegate

            required property int index
            readonly property date date: Calendar.Utils.addDaysToDate(root.startDate, index)
            readonly property string formatedDate: Qt.formatDate(date, 'yyyy-MM-dd')
            readonly property var holidays: Calendar.HolidayModel.holidays[formatedDate]

            width: root.dayWidth
            implicitHeight: holidayLabel.implicitHeight
            color: holidays.length > 0 ? Kirigami.Theme.negativeBackgroundColor : Kirigami.Theme.backgroundColor

            QQC2.Label {
                id: holidayLabel
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                padding: Kirigami.Units.smallSpacing
                font.bold: true
                color: Kirigami.Theme.negativeTextColor
                text: delegate.holidays.join("\n")
            }
        }
    }

    Rectangle {
        color: Kirigami.Theme.backgroundColor
        height: parent.height
        width: root.scrollbarWidth
    }
}
