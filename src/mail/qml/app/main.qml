// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.merkuro.components 1.0
import org.kde.merkuro.mail 1.0 as Mail
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.20 as Kirigami

BaseApplication {
    id: root

    application: Mail.MailApplication

    menuBar: Loader {
        active: !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile && applicationWindow().pageStack.currentItem

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
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/qml/settings/Settings.qml", {
                width: root.width
            }, {
                title: i18n("Configure"),
                width: Kirigami.Units.gridUnit * 40,
                height: Kirigami.Units.gridUnit * 30
            });
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }
    }
}
