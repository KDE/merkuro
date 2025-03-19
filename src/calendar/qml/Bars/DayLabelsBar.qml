// SPDX-FileCopyrightText: 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

Row {
    id: root
    property date startDate
    property real dayWidth
    property real daysToShow

    height: childrenRect.height

    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 40
    readonly property bool isTiny: width < Kirigami.Units.gridUnit * 18

    spacing: 0
    Repeater {
        model: root.daysToShow
        delegate: QQC2.Control {
            id: delegate
            required property int modelData
            property date day: Calendar.DateUtils.addDaysToDate(root.startDate, modelData)

            width: root.dayWidth

            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
            contentItem: Kirigami.Heading {
                text: {
                    const longText = delegate.day.toLocaleString(Qt.locale(), "dddd");
                    const midText = delegate.day.toLocaleString(Qt.locale(), "ddd");
                    const shortText = Qt.locale().name.startsWith("zh_") ? midText.slice(-1) : midText.slice(0, 1);
                    switch(Calendar.Config.weekdayLabelLength) {
                        case Calendar.Config.Full:
                            let chosenFormat = "dddd"
                            return root.isLarge ? longText : root.isTiny ? shortText : midText;
                        case Calendar.Config.Abbreviated:
                            return root.isTiny ? shortText : midText;
                        case Calendar.Config.Letter:
                        default:
                            return shortText;
                    }
                }
                level: 2
                leftPadding: Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.smallSpacing
                horizontalAlignment: {
                    switch(Calendar.Config.weekdayLabelAlignment) {
                        case Calendar.Config.Left:
                            return Text.AlignLeft;
                        case Calendar.Config.Center:
                            return Text.AlignHCenter;
                        case Calendar.Config.Right:
                            return Text.AlignRight;
                        default:
                            return Text.AlignHCenter;
                    }
                }
            }
        }
    }
}

