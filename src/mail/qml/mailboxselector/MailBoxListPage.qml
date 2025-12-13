// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.raven

Kirigami.ScrollablePage {
    id: root
    title: i18n("Mailboxes")
    
    MailBoxList {}
}
