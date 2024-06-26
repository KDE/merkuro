// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.components 1.0
import org.kde.merkuro.mail 1.0 as Mail
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.20 as Kirigami
import org.kde.merkuro.mail.settings as Settings

BaseApplication {
    id: root

    application: Mail.MailApplication

    menuBar: Loader {
        active: Config.showMenubar && !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile && applicationWindow().pageStack.currentItem

        height: visible ? implicitHeight : 0
        sourceComponent: MenuBar {}
        onItemChanged: if (item) {
            item.Kirigami.Theme.colorSet = Kirigami.Theme.Header;
        }
    }

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
