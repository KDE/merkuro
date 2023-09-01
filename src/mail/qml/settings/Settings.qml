// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigamiaddons.settings 1.0 as KirigamiSettings

KirigamiSettings.CategorizedSettings {
    objectName: "settingsPage"
    actions: [
        KirigamiSettings.SettingAction {
            actionName: "accounts"
            text: i18nc("@title", "Accounts")
            icon.name: "preferences-system-users"
            page: Qt.resolvedUrl("AccountSettingsPage.qml")
        }
    ]
}
