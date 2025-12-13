// SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Qt.labs.platform as Labs

import QtQuick
import org.kde.merkuro.calendar
import org.kde.merkuro.components
import org.kde.kirigamiaddons.statefulapp.labs as StatefulAppLabs

Labs.MenuBar {
    id: bar

    NativeFileMenu {
        StatefulAppLabs.NativeMenuItem {
            actionName: "import_calendar"
            application: CalendarApplication
        }
    }

    NativeEditMenu {
        id: editMenu

        Labs.MenuSeparator {}

        StatefulAppLabs.NativeMenuItem {
            actionName: "edit_redo"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "edit_undo"
            application: CalendarApplication
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "View")

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_month_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_week_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_workweek_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_threeday_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_day_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_schedule_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_todo_view"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "open_kcommand_bar"
            application: CalendarApplication
        }

        Labs.MenuSeparator {
        }

        Labs.Menu {
            title: i18nc("@action:menu", "Sort Tasks")
            enabled: mode === CalendarApplication.Todo

            StatefulAppLabs.NativeMenuItem {
                actionName: "todoview_sort_by_due_date"
                application: CalendarApplication
            }

            StatefulAppLabs.NativeMenuItem {
                actionName: "todoview_sort_by_priority"
                application: CalendarApplication
            }

            StatefulAppLabs.NativeMenuItem {
                actionName: "todoview_sort_alphabetically"
                application: CalendarApplication
            }

            Labs.MenuSeparator {
            }

            StatefulAppLabs.NativeMenuItem {
                actionName: "todoview_order_ascending"
                application: CalendarApplication
            }

            StatefulAppLabs.NativeMenuItem {
                actionName: "todoview_order_descending"
                application: CalendarApplication
            }
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "todoview_show_completed"
            application: CalendarApplication
            enabled: mode === CalendarApplication.Todo
        }

        Labs.MenuSeparator {
        }

        StatefulAppLabs.NativeMenuItem {
            text: i18n("Refresh All Calendars")
            actionName: "refresh_all"
            application: CalendarApplication
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Go")

        StatefulAppLabs.NativeMenuItem {
            actionName: "move_view_backwards"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }
        StatefulAppLabs.NativeMenuItem {
            actionName: "move_view_forwards"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }

        Labs.MenuSeparator {}

        StatefulAppLabs.NativeMenuItem {
            actionName: "move_view_to_today"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }
        StatefulAppLabs.NativeMenuItem {
            actionName: "open_date_changer"
            application: CalendarApplication
            enabled: mode & CalendarApplication.Event
        }
    }

    Labs.Menu {
        title: i18nc("@action:menu", "Create")

        StatefulAppLabs.NativeMenuItem {
            actionName: "create_event"
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: "create_todo"
            application: CalendarApplication
        }
    }

    NativeWindowMenu {}

    Labs.Menu {
        title: i18nc("@action:menu", "Settings")

        StatefulAppLabs.NativeMenuItem {
            actionName: 'open_tag_manager'
            application: CalendarApplication
        }

        Labs.MenuSeparator {}

        StatefulAppLabs.NativeMenuItem {
            actionName: 'options_configure_keybinding'
            application: CalendarApplication
        }

        StatefulAppLabs.NativeMenuItem {
            actionName: 'options_configure'
            application: CalendarApplication
        }
    }

    NativeHelpMenu {
        application: CalendarApplication
    }
}
