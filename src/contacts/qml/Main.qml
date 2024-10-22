// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.merkuro.components
import org.kde.merkuro.contact as Contact
import org.kde.akonadi as Akonadi
import org.kde.kirigami as Kirigami

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

        function onOpenSettings(): void {
            const openDialogWindow = pageStack.pushDialogLayer(Qt.createComponent("org.kde.merkuro.contact", "Settings"), {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });
        }

        function onRefreshAll(): void {
            Contact.ContactManager.updateAllCollections();
        }

        function onShowMenubarChanged(state: bool): void {
            Contact.ContactConfig.showMenubar = state;
        }
    }
}
