// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import Qt.labs.qmlmodels

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels
import org.kde.raven 1.0

Kirigami.ScrollablePage {
    id: root
    title: i18n("Mailboxes")
    
    MailBoxList {}
}
