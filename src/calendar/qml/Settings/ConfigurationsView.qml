// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import org.kde.kirigamiaddons.settings as KirigamiSettings

KirigamiSettings.ConfigurationView {
    objectName: "settingsPage"
    modules: [
        KirigamiSettings.ConfigurationModule {
            moduleId: "users"
            text: i18n("Calendars & Accounts")
            icon.name: "preferences-system-users"
            page: () => Qt.createComponent("SourceSettingsPage.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "appearance"
            text: i18n("Calendar Views")
            icon.name: "view-calendar-month"
            page: () => Qt.createComponent("ViewSettingsPage.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "tasks"
            text: i18n("Tasks")
            icon.name: "view-task"
            page: function(): Component {
                return Qt.createComponent("TaskSettingsPage.qml");
            }
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "locations"
            text: i18n("Locations")
            icon.name: "mark-location"
            page: function(): Component {
                return Qt.createComponent("LocationSettingsPage.qml");
            }
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "freebusy"
            text: i18n("Availability")
            icon.name: "view-calendar-month"
            page: () => Qt.createComponent("FreeBusySettingsPage.qml")
        }
    ]
}
