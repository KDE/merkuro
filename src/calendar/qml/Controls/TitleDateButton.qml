// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

QQC2.ToolButton {
    id: root

    property bool range: false
    property date lastDate
    readonly property date date: Calendar.DateTimeState.firstDayOfMonth

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    Accessible.name: contentItem.text.replace(/<\/?b>/g, '')

    contentItem: Kirigami.Heading {
        topPadding: Kirigami.Units.smallSpacing
        bottomPadding: Kirigami.Units.smallSpacing
        leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

        horizontalAlignment: Text.AlignHCenter
        text: {
            const locale = Qt.locale();
            const monthYearString = i18nc("%1 is month name, %2 is year", "<b>%1</b> %2", locale.standaloneMonthName(root.date.getMonth()), String(root.date.getFullYear()));

            if(!root.range) {
                return monthYearString;
            } else {
                const endRangeMonthYearString = i18nc("%1 is month name, %2 is year", "<b>%1</b> %2", locale.standaloneMonthName(root.lastDate.getMonth()), String(root.lastDate.getFullYear()));

                if(root.date.getFullYear() !== root.lastDate.getFullYear()) {
                    return i18nc("%1 is the month and year of the range start, %2 is the same for range end", "%1 – %2", monthYearString, endRangeMonthYearString);
                } else if(root.date.getMonth() !== root.lastDate.getMonth()) {
                    return i18nc("%1 is month of range start, %2 is month + year of range end", "<b>%1</b> – %2", locale.standaloneMonthName(root.date.getMonth()), endRangeMonthYearString);
                } else {
                    return monthYearString;
                }
            }
        }
    }
}
