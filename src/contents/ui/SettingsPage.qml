// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15

Kirigami.CategorizedSettings {
    objectName: "settingsPage"
    actions: [
        Kirigami.SettingAction {
            text: i18n("General")
            icon.name: "korganizer"
            page: Qt.resolvedUrl("GeneralSettingsPage.qml")
        },
        Kirigami.SettingAction {
            text: i18n("Views")
            icon.name: "view-choose"
            page: Qt.resolvedUrl("ViewSettingsPage.qml")
        },
        Kirigami.SettingAction {
            text: i18n("Calendar Sources")
            icon.name: "preferences-system-users"
            page: Qt.resolvedUrl("SourceSettingsPage.qml")
        },
        Kirigami.SettingAction {
            text: i18n("Calendars")
            icon.name: "korganizer"
            page: Qt.resolvedUrl("CalendarSettingsPage.qml")
        },
        Kirigami.SettingAction {
            text: i18n("About Kalendar")
            icon.name: "help-about"
            page: Qt.resolvedUrl("AboutPage.qml")
        }
    ]
}
