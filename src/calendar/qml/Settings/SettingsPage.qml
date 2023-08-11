// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigamiaddons.settings 1.0 as KirigamiSettings
import org.kde.merkuro.calendar 1.0

KirigamiSettings.CategorizedSettings {
    objectName: "settingsPage"
    actions: [
        KirigamiSettings.SettingAction {
            actionName: "appearance"
            text: i18n("Appearance")
            icon.name: "preferences-desktop-theme-global"
            page: Qt.resolvedUrl("ViewSettingsPage.qml")
        },
        KirigamiSettings.SettingAction {
            actionName: "users"
            text: i18n("Accounts")
            icon.name: "preferences-system-users"
            page: Qt.resolvedUrl("SourceSettingsPage.qml")
        },
        KirigamiSettings.SettingAction {
            actionName: "freebusy"
            text: i18n("Free/Busy")
            icon.name: "view-calendar-month"
            page: Qt.resolvedUrl("FreeBusySettingsPage.qml")
        }
    ]
}
