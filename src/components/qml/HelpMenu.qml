// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.kirigami as Kirigami

QQC2.Menu {
    id: root

    required property AbstractMerkuroApplication application

    title: i18nc("@action:menu", "Help")

    Kirigami.Action {
        fromQAction: root.application.action('open_about_page')
    }

    Kirigami.Action {
        fromQAction: root.application.action('open_about_kde_page')
    }

    QQC2.MenuItem {
        text: i18nc("@action:menu", "Merkuro Handbook") // todo
        visible: false
    }
}
