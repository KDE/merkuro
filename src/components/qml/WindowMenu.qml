// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.ki18n

QQC2.Menu {
    property Window _window: applicationWindow()

    title: KI18n.i18nc("@action:menu", "Window")

    Kirigami.Action {
        text: _window.visibility === Window.FullScreen ? KI18n.i18nc("@action:menu", "Exit Full Screen") : KI18n.i18nc("@action:menu", "Enter Full Screen")
        icon.name: "view-fullscreen"
        shortcut: StandardKey.FullScreen
        onTriggered: if (_window.visibility === Window.FullScreen) {
            _window.showNormal();
        } else {
            _window.showFullScreen();
        }
    }
}
