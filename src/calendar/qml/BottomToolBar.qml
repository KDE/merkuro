// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020-2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import org.kde.kirigami 2.19 as Kirigami
import org.kde.merkuro.components 1.0
import org.kde.merkuro.calendar 1.0 as Calendar
import org.kde.kirigamiaddons.statefulapp as StatefulApp

Kirigami.NavigationTabBar {
    actions: [
        StatefulApp.Action {
            actionName: "open_month_view"
            property string name: "monthView"
        },
        StatefulApp.Action {
            actionName: "open_threeday_view"
            property string name: "threeDayView"
        },
        StatefulApp.Action {
            actionName: "open_day_view"
            property string name: "dayView"
        },
        StatefulApp.Action {
            actionName: "open_schedule_view"
            property string name: "scheduleView"
        },
        StatefulApp.Action {
            actionName: "open_todo_view"
            property string name: "todoView"
        }
    ]
}
