// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.merkuro.mail as Mail
import org.kde.akonadi as Akonadi
import org.kde.kirigami as Kirigami
import org.kde.merkuro.mail.settings as Settings

BaseApplication {
    id: root

    property string searchString: ''

    application: Mail.MailApplication

    menubarComponent: MenuBar {}

    pageStack.initialPage: Mail.FolderView {
        searchString: root.searchString
    }

    globalDrawer: Mail.MailSidebar {
        id: sidebar

        onSearch: (searchString) => {
            root.searchString = searchString;
        }
    }

    //Loader {
    //    id: globalMenuLoader
    //    active: !Kirigami.Settings.isMobile
    //    sourceComponent: Contact.GlobalMenuBar {}
    //}

    Connections {
        target: Mail.MailApplication

        function onOpenSettings(): void {
            settings.open();
        }

        function onCheckMail(): void {
            Mail.MailManager.checkMail();
        }

        function onCreateNewMail(): void {
            applicationWindow().pageStack.pushDialogLayer(Qt.createComponent("org.kde.merkuro.mail", "MailComposer"))
        }
    }

    Settings.Settings {
        id: settings
        window: root
    }
}
