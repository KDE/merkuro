// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Window
import org.kde.merkuro.calendar
import org.kde.merkuro.components

QQC2.MenuBar {
    id: bar
    FileMenu {
        Kirigami.Action {
            fromQAction: CalendarApplication.action("import_calendar")
        }
    }

    EditMenu {
        Kirigami.Action {
            fromQAction: CalendarApplication.action('edit_undo')
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action('edit_redo')
        }

        QQC2.MenuSeparator {}
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_month_view")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_week_view")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_threeday_view")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_day_view")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_schedule_view")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_todo_view")
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: applicationWindow().mode === CalendarApplication.Todo

            Kirigami.Action {
                fromQAction: CalendarApplication.action("todoview_sort_by_due_date")
            }

            Kirigami.Action {
                fromQAction: CalendarApplication.action("todoview_sort_by_priority")
            }

            Kirigami.Action {
                fromQAction: CalendarApplication.action("todoview_sort_alphabetically")
            }

            QQC2.MenuSeparator {
            }

            Kirigami.Action {
                fromQAction: CalendarApplication.action("todoview_order_ascending")
            }

            Kirigami.Action {
                fromQAction: CalendarApplication.action("todoview_order_descending")
            }
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("todoview_show_completed")
            enabled: mode === CalendarApplication.Todo
        }

        QQC2.MenuSeparator {}

        Kirigami.Action {
            fromQAction: CalendarApplication.action('open_kcommand_bar')
        }

        Kirigami.Action {
            text: i18n("Refresh All Calendars")
            fromQAction: CalendarApplication.action("refresh_all")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Go")

        Kirigami.Action {
            fromQAction: CalendarApplication.action("move_view_backwards")
            enabled: mode & CalendarApplication.Event
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("move_view_forwards")
            enabled: mode & CalendarApplication.Event
        }

        QQC2.MenuSeparator {}

        Kirigami.Action {
            fromQAction: CalendarApplication.action("move_view_to_today")
            enabled: mode & CalendarApplication.Event
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("open_date_changer")
            enabled: mode & CalendarApplication.Event
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        Kirigami.Action {
            fromQAction: CalendarApplication.action("create_event")
        }

        Kirigami.Action {
            fromQAction: CalendarApplication.action("create_todo")
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
