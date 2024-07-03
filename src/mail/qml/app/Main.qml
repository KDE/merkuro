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

    application: Mail.MailApplication

    menubarComponent: MenuBar {}

    pageStack.initialPage: Mail.FolderView {}

    globalDrawer: Mail.MailSidebar {
        id: sidebar
    }

    //Loader {
    //    id: globalMenuLoader
    //    active: !Kirigami.Settings.isMobile
    //    sourceComponent: Contact.GlobalMenuBar {}
    //}

    Connections {
        target: Mail.MailApplication

        function onOpenSettings() {
            settings.open();
        }

        function onCheckMail() {
            Mail.MailManager.checkMail();
        }
    }

    Settings.Settings {
        id: settings
        window: root
    }
}
