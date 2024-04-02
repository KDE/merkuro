// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import org.kde.kirigamiaddons.dateandtime

RowLayout {
    id: root

    property alias titleDateButton: titleDateButton
    readonly property var openDateChangerAction: Calendar.CalendarApplication.action("open_date_changer")

    spacing: 0

    MainDrawerToggleButton {}

    TitleDateButton {
        id: titleDateButton

        onClicked: {
            if (!dateChangerLoader.active) {
                dateChangerLoader.active = true;
                return;
            }

            if (dateChangerLoader.item.visible) {
                dateChangerLoader.item.close();
            } else {
                dateChangerLoader.item.open();
            }
        }
    }

    Connections {
        target: Calendar.CalendarApplication

        function onOpenDateChanger() {
            dateChangerLoader.active = true;
        }
    }

    Loader {
        id: dateChangerLoader
        active: false
        visible: status === Loader.Ready
        onStatusChanged: if(status === Loader.Ready) {
            item.open()
        }
        sourceComponent: DatePopup {
            y: pageStack.globalToolBar.height - 1
            x: 0
            parent: titleDateButton
            value: Calendar.DateTimeState.selectedDate
            implicitWidth: Kirigami.Units.gridUnit * 20
            autoAccept: true
            onAccepted: {
                close();
                Calendar.DateTimeState.selectedDate = value;
            }
        }
    }
}
