// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.merkuro.components 1.0
import org.kde.merkuro.contact 1.0 as Contact
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.20 as Kirigami

BaseApplication {
    id: root

    application: Contact.ContactApplication

    title: pageStack.currentItem.title

    menubarComponent: Contact.MenuBar {}

    pageStack.initialPage: Contact.ContactView {}

    globalDrawer: Contact.Sidebar {
        id: sidebar
    }

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile
        sourceComponent: Contact.GlobalMenuBar {}
    }

    Connections {
        target: Contact.ContactApplication

        function onOpenSettings() {
            const openDialogWindow = pageStack.pushDialogLayer("qrc:/qml/Settings.qml", {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });
        }

        function onRefreshAll() {
            Contact.ContactManager.updateAllCollections();
        }
        function onShowMenubarChanged(state) {
            Config.showMenubar = state;
        }
    }
}
