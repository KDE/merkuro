// SPDX-FileCopyrightText: 2023 Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.pim.mimetreeparser
import org.kde.merkuro.mail.desktop

Kirigami.ApplicationWindow {
    id: root

    readonly property Kirigami.Action openFileAction: Kirigami.Action {
        text: i18n("Open File")
        onTriggered: fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: i18n("Choose file")
        onAccepted: messageHandler.open(fileUrl)
    }

    MessageHandler {
        id: messageHandler
        objectName: "MessageHandler"
        onMessageOpened: pageStack.currentItem.message = message
    }

    pageStack.initialPage: MailViewer {
    }
}
