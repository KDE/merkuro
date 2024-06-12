// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Window
import org.kde.merkuro.calendar
import org.kde.merkuro.components
import org.kde.kirigamiaddons.statefulapp as StatefulApp

QQC2.MenuBar {
    id: bar
    FileMenu {
        QQC2.MenuItem {
            action: StatefulApp.Action {
                actionName: "import_calendar"
            }
        }
    }

    EditMenu {
        QQC2.MenuItem {
            action: StatefulApp.Action {
                actionName: "edit_undo"
            }
        }

        QQC2.MenuItem {
            action: StatefulApp.Action {
                actionName: "edit_redo"
            }
        }

        QQC2.MenuSeparator {
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        StatefulApp.Action {
            actionName: "open_month_view"
        }

        StatefulApp.Action {
            actionName: "open_week_view"
        }

        StatefulApp.Action {
            actionName: "open_threeday_view"
        }

        StatefulApp.Action {
            actionName: "open_day_view"
        }

        StatefulApp.Action {
            actionName: "open_schedule_view"
        }

        StatefulApp.Action {
            actionName: "open_todo_view"
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: applicationWindow().mode === CalendarApplication.Todo

            StatefulApp.Action {
                actionName: "todoview_sort_by_due_date"
            }

            StatefulApp.Action {
                actionName: "todoview_sort_by_priority"
            }

            StatefulApp.Action {
                actionName: "todoview_sort_alphabetically"
            }

            QQC2.MenuSeparator {
            }

            StatefulApp.Action {
                actionName: "todoview_order_ascending"
            }

            StatefulApp.Action {
                actionName: "todoview_order_descending"
            }
        }

        StatefulApp.Action {
            actionName: "todoview_show_completed"
            enabled: mode === CalendarApplication.Todo
        }

        QQC2.MenuSeparator {}

        StatefulApp.Action {
            actionName: 'open_kcommand_bar'
        }

        StatefulApp.Action {
            text: i18n("Refresh All Calendars")
            actionName: "refresh_all"
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Go")

        StatefulApp.Action {
            actionName: "move_view_backwards"
            enabled: mode & CalendarApplication.Event
        }

        StatefulApp.Action {
            actionName: "move_view_forwards"
            enabled: mode & CalendarApplication.Event
        }

        QQC2.MenuSeparator {}

        StatefulApp.Action {
            actionName: "move_view_to_today"
            enabled: mode & CalendarApplication.Event
        }

        StatefulApp.Action {
            actionName: "open_date_changer"
            enabled: mode & CalendarApplication.Event
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        StatefulApp.Action {
            actionName: "create_event"
        }

        StatefulApp.Action {
            actionName: "create_todo"
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: CalendarApplication
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Help")

        StatefulApp.Action {
            actionName: "open_about_page"
        }

        StatefulApp.Action {
            actionName: "open_about_kde_page"
        }

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Calendar Handbook") // todo
            visible: false
        }
    }
}
