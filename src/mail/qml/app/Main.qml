// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.merkuro.components
import org.kde.merkuro.mail as Mail
import org.kde.merkuro.mail.settings as Settings

BaseApplication {
    id: root

    property string searchString: ''

    function showMessage(itemId: real): void {
        root.pageStack.layers.push(conversationViewerComponent, {
            itemId: itemId,
            mailActions: folderView.viewerMailActions,
        });
    }

    Component {
        id: conversationViewerComponent
        Mail.ConversationViewer {}
    }

    merkuroApplication: Mail.MailApplication

    menubarComponent: MenuBar {}

    pageStack.initialPage: Mail.FolderView {
        id: folderView
        searchString: root.searchString
    }

    globalDrawer: Mail.MailSidebar {
        id: sidebar

        pageStack: root.pageStack

        onSearch: (searchString) => {
            root.searchString = searchString;
        }
    }

    Loader {
       id: globalMenuLoader
       active: !Kirigami.Settings.isMobile
       sourceComponent: GlobalMenuBar {
           application: root.application
        }
    }

    Connections {
        target: Mail.MailApplication

        function onOpenSettings(): void {
            settings.open();
        }

        function onCheckMail(): void {
            Mail.MailManager.checkMail();
        }

        function onCreateNewMail(): void {
            root.pageStack.pushDialogLayer(Qt.createComponent("org.kde.merkuro.mail", "MailComposer"))
        }
        function onErrorOccurred(error: string): void {
            root.showPassiveNotification(error)
        }
    }

    Connections {
        target: Mail.MailManager

        function onErrorOccurred(error: string): void {
            root.showPassiveNotification(error);
        }
    }

    Settings.Settings {
        id: settings
        window: root
    }
}
