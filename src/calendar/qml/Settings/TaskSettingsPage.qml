// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.calendar as Calendar

FormCard.FormCardPage {
    title: i18n("Tasks")

    FormCard.FormHeader {
        title: i18n("Calendar Views")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: showTasks
            objectName: "showCalendarTasksSwitch"
            text: i18n("Show tasks in calendar views")
            checked: Calendar.Config.showTodosInCalendarViews
            enabled: !Calendar.Config.isShowTodosInCalendarViewsImmutable
            onToggled: {
                Calendar.Config.showTodosInCalendarViews = showTasks.checked;
                Calendar.Config.save();
            }
        }

        FormCard.FormSwitchDelegate {
            id: showSubtasks
            objectName: "showCalendarSubtasksSwitch"
            text: i18n("Show subtasks in calendar views")
            checked: Calendar.Config.showSubtodosInCalendarViews
            enabled: Calendar.Config.showTodosInCalendarViews && !Calendar.Config.isShowSubtodosInCalendarViewsImmutable
            onToggled: {
                Calendar.Config.showSubtodosInCalendarViews = showSubtasks.checked;
                Calendar.Config.save();
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Task View")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: showCompletedSubtasks
            objectName: "showCompletedSubtasksSwitch"
            text: i18n("Show completed subtasks")
            checked: Calendar.Config.showCompletedSubtodos
            enabled: !Calendar.Config.isShowCompletedSubtodosImmutable
            onToggled: {
                Calendar.Config.showCompletedSubtodos = showCompletedSubtasks.checked;
                Calendar.Config.save();
            }
        }
    }
}
