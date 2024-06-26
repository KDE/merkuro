// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Window
import org.kde.merkuro.calendar 1.0
import org.kde.merkuro.components 1.0

QQC2.MenuBar {
    id: bar
    FileMenu {
        QQC2.MenuItem {
            action: KActionFromAction {
                action: CalendarApplication.action("import_calendar")
            }
        }
    }

    EditMenu {
        QQC2.MenuItem {
            action: KActionFromAction {
                action: CalendarApplication.action("edit_undo")
            }
        }

        QQC2.MenuItem {
            action: KActionFromAction {
                action: CalendarApplication.action("edit_redo")
            }
        }

        QQC2.MenuSeparator {
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "View")

        KActionFromAction {
            action: CalendarApplication.action("open_month_view")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_week_view")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_threeday_view")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_day_view")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_schedule_view")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_todo_view")
        }

        QQC2.MenuSeparator {
        }

        QQC2.Menu {
            title: i18n("Sort Tasks")
            enabled: applicationWindow().mode === CalendarApplication.Todo

            KActionFromAction {
                action: CalendarApplication.action("todoview_sort_by_due_date")
            }
            KActionFromAction {
                action: CalendarApplication.action("todoview_sort_by_priority")
            }
            KActionFromAction {
                action: CalendarApplication.action("todoview_sort_alphabetically")
            }

            QQC2.MenuSeparator {
            }

            KActionFromAction {
                action: CalendarApplication.action("todoview_order_ascending")
            }
            KActionFromAction {
                action: CalendarApplication.action("todoview_order_descending")
            }
        }

        KActionFromAction {
            action: CalendarApplication.action("todoview_show_completed")
            enabled: mode === CalendarApplication.Todo
        }

        QQC2.MenuSeparator {}

        KActionFromAction {
            action: CalendarApplication.action('open_kcommand_bar')
        }

        KActionFromAction {
            text: i18n("Refresh All Calendars")
            action: CalendarApplication.action("refresh_all")
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Go")

        KActionFromAction {
            action: CalendarApplication.action("move_view_backwards")
            enabled: mode & CalendarApplication.Event
        }
        KActionFromAction {
            action: CalendarApplication.action("move_view_forwards")
            enabled: mode & CalendarApplication.Event
        }

        QQC2.MenuSeparator {}

        KActionFromAction {
            action: CalendarApplication.action("move_view_to_today")
            enabled: mode & CalendarApplication.Event
        }
        KActionFromAction {
            action: CalendarApplication.action("open_date_changer")
            enabled: mode & CalendarApplication.Event
        }
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Create")

        KActionFromAction {
            action: CalendarApplication.action("create_event")
        }
        KActionFromAction {
            action: CalendarApplication.action("create_todo")
        }
    }

    WindowMenu {}

    SettingsMenu {
        application: CalendarApplication
    }

    QQC2.Menu {
        title: i18nc("@action:menu", "Help")

        KActionFromAction {
            action: CalendarApplication.action("open_about_page")
        }

        KActionFromAction {
            action: CalendarApplication.action("open_about_kde_page")
        }

        QQC2.MenuItem {
            text: i18nc("@action:menu", "Calendar Handbook") // todo
            visible: false
        }
    }
}
