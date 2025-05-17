// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigamiaddons.settings 1.0 as KirigamiSettings
import org.kde.merkuro.calendar

KirigamiSettings.ConfigurationView {
    objectName: "settingsPage"
    modules: [
        KirigamiSettings.ConfigurationModule {
            moduleId: "appearance"
            text: i18n("Appearance")
            icon.name: "preferences-desktop-theme-global"
            page: () => Qt.createComponent("ViewSettingsPage.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "users"
            text: i18n("Accounts")
            icon.name: "preferences-system-users"
            page: () => Qt.createComponent("SourceSettingsPage.qml")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "freebusy"
            text: i18n("Availability")
            icon.name: "view-calendar-month"
            page: () => Qt.createComponent("FreeBusySettingsPage.qml")
        }
    ]
}
