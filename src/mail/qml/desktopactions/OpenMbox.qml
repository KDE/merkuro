// SPDX-FileCopyrightText: 2023 Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.pim.mimetreeparser
import org.kde.merkuro.mail
import org.kde.ki18n

Kirigami.ApplicationWindow {
    id: root

    readonly property alias fileMessageHandler: messageHandler

    readonly property Kirigami.Action openFileAction: Kirigami.Action {
        text: KI18n.i18n("Open File")
        onTriggered: fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: KI18n.i18n("Choose file")
        onAccepted: root.fileMessageHandler.open(fileDialog.selectedFile)
    }

    MessageHandler {
        id: messageHandler
        objectName: "MessageHandler"
        // qmllint disable signal-handler-parameters
        function onMessageOpened(message: var): void {
            root.pageStack.currentItem.message = message;
        }
        // qmllint enable signal-handler-parameters
    }

    pageStack.initialPage: MailViewer {
    }
}
