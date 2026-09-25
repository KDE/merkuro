// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.ki18n

Kirigami.Action {
    required property Kirigami.ApplicationWindow application
    required property ContactImportExport exporter
    required property int itemId

    text: KI18n.i18nc("@action:inmenu", "Share Contact")
    icon.name: "emblem-shared-symbolic"
    visible: false
}
