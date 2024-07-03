// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020-2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.merkuro.components
import org.kde.merkuro.calendar as Calendar
import org.kde.kirigamiaddons.statefulapp as StatefulApp

Kirigami.NavigationTabBar {
    actions: [
        StatefulApp.Action {
            property string name: "monthView"
            actionName: "open_month_view"
            application: Calendar.CalendarApplication
        },
        StatefulApp.Action {
            actionName: "open_threeday_view"
            property string name: "threeDayView"
            application: Calendar.CalendarApplication
        },
        StatefulApp.Action {
            actionName: "open_day_view"
            property string name: "dayView"
            application: Calendar.CalendarApplication
        },
        StatefulApp.Action {
            actionName: "open_schedule_view"
            property string name: "scheduleView"
            application: Calendar.CalendarApplication
        },
        StatefulApp.Action {
            actionName: "open_todo_view"
            property string name: "todoView"
            application: Calendar.CalendarApplication
        }
    ]
}
