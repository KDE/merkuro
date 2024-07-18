// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2020 Han Young <hanyoung@protonmail.com>
// SPDX-FileCopyrightText: 2020-2021 Devin Lin <espidev@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.merkuro.components
import org.kde.merkuro.calendar as Calendar

Kirigami.NavigationTabBar {
    actions: [
        Kirigami.Action {
            property string name: "monthView"
            fromQAction: Calendar.CalendarApplication.action("open_month_view")
        },
        Kirigami.Action {
            fromQAction: Calendar.CalendarApplication.action("open_threeday_view")
            property string name: "threeDayView"
        },
        Kirigami.Action {
            fromQAction: Calendar.CalendarApplication.action("open_day_view")
            property string name: "dayView"
        },
        Kirigami.Action {
            fromQAction: Calendar.CalendarApplication.action("open_schedule_view")
            property string name: "scheduleView"
        },
        Kirigami.Action {
            fromQAction: Calendar.CalendarApplication.action("open_todo_view")
            property string name: "todoView"
        }
    ]
}
