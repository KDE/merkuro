// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import org.kde.kalendar.mail 1.0

import './mailboxselector'

QQC2.ScrollView {
    id: folderListView

    implicitWidth: Kirigami.Units.gridUnit * 16
    contentWidth: availableWidth

    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    contentItem: MailBoxList { }

    property Kirigami.PagePool pagePool: Kirigami.PagePool {
        id: pagePool
    }

    function getPage(name) {
        switch (name) {
        case "FolderView":
            return pagePool.loadPage(Qt.resolvedUrl("./FolderView.qml"))
        case "MailBoxListPage":
            return pagePool.loadPage(Qt.resolvedUrl("./mailboxselector/MailBoxListPage.qml"))
        }
    }
}