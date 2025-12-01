// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import org.kde.kirigamiaddons.settings as KirigamiSettings

KirigamiSettings.ConfigurationView {
    objectName: "settingsPage"
    modules: [
        KirigamiSettings.ConfigurationModule {
            moduleId: "accounts"
            text: i18nc("@title", "Accounts")
            icon.name: "preferences-system-users"
            page: () => Qt.createComponent("AccountSettingsPage.qml")
        }
    ]
}
