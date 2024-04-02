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

        onClicked: if (Calendar.DatePopupSingleton.visible) {
            Calendar.DatePopupSingleton.close();
            connect.enabled = false;
        } else {
            Calendar.DatePopupSingleton.y = pageStack.globalToolBar.height - 1;
            Calendar.DatePopupSingleton.x = 0;
            Calendar.DatePopupSingleton.value = Calendar.DateTimeState.selectedDate
            Calendar.DatePopupSingleton.popupParent = titleDateButton;
            connect.enabled = true;
            Calendar.DatePopupSingleton.open();
        }

        Connections {
            id: connect

            enabled: false
            target: Calendar.DatePopupSingleton

            function onAccepted(): void {
                Calendar.DatePopupSingleton.close();
                Calendar.DateTimeState.selectedDate = Calendar.DatePopupSingleton.value;
            }

            function onClosed(): void {
                connect.enabled = false;
            }
        }
    }

    Connections {
        target: Calendar.CalendarApplication

        function onOpenDateChanger(): void {
            titleDateButton.clicked();
        }
    }
}
