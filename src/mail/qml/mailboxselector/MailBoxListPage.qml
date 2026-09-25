// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.ki18n

Kirigami.ScrollablePage {
    id: root
    title: KI18n.i18n("Mailboxes")
    
    MailBoxList {
        collectionId: -1
        name: ""
        resourceIdentifier: ""
    }
}
