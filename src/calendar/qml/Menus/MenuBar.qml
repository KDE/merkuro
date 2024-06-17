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
                application: CalendarApplication
            }
        }
    }

    EditMenu {
        QQC2.MenuItem {
            action: StatefulApp.Action {
                actionName: "edit_undo"
                application: CalendarApplication
            }
        }

        QQC2.MenuItem {
            action: StatefulApp.Action {
                actionName: "edit_redo"
                application: CalendarApplication
            }
        }

        QQC2.MenuSeparator {
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        StatefulApp.Action {
            actionName: "open_month_view"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "open_week_view"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "open_threeday_view"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "open_day_view"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "open_schedule_view"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "open_todo_view"
            application: CalendarApplication
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: applicationWindow().mode === CalendarApplication.Todo

            StatefulApp.Action {
                actionName: "todoview_sort_by_due_date"
                application: CalendarApplication
            }

            StatefulApp.Action {
                actionName: "todoview_sort_by_priority"
                application: CalendarApplication
            }

            StatefulApp.Action {
                actionName: "todoview_sort_alphabetically"
                application: CalendarApplication
            }

            QQC2.MenuSeparator {
            }

            StatefulApp.Action {
                actionName: "todoview_order_ascending"
                application: CalendarApplication
            }

            StatefulApp.Action {
                actionName: "todoview_order_descending"
                application: CalendarApplication
            }
        }

        StatefulApp.Action {
            actionName: "todoview_show_completed"
            application: CalendarApplication
            enabled: mode === CalendarApplication.Todo
        }

        QQC2.MenuSeparator {}

        StatefulApp.Action {
            actionName: 'open_kcommand_bar'
            application: CalendarApplication
        }

        StatefulApp.Action {
            text: i18n("Refresh All Calendars")
            actionName: "refresh_all"
            application: CalendarApplication
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Go")

        StatefulApp.Action {
            actionName: "move_view_backwards"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }

        StatefulApp.Action {
            actionName: "move_view_forwards"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }

        QQC2.MenuSeparator {}

        StatefulApp.Action {
            actionName: "move_view_to_today"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }

        StatefulApp.Action {
            actionName: "open_date_changer"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        StatefulApp.Action {
            actionName: "create_event"
            application: CalendarApplication
        }

        StatefulApp.Action {
            actionName: "create_todo"
            application: CalendarApplication
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: CalendarApplication
    }

    HelpMenu {
        application: CalendarApplication
    }
}
