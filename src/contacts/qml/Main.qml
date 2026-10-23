// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.merkuro.components
import org.kde.merkuro.contact as Contact
import org.kde.kirigami as Kirigami

BaseApplication {
    id: root

    merkuroApplication: Contact.ContactApplication

    title: (root.pageStack.currentItem as Kirigami.Page).title

    menubarComponent: Contact.MenuBar {}

    pageStack.initialPage: sidebar.showMap ? mapPage : contactsPage

    Component {
        id: contactsPage
        Contact.ContactView {}
    }

    Component {
        id: mapPage
        Contact.ContactMapPage {}
    }

    globalDrawer: Contact.Sidebar {
        id: sidebar
	pageStack: root.pageStack
    }

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile
        sourceComponent: Contact.GlobalMenuBar {}
    }

    Component.onCompleted: Contact.AvatarImageProvider.init()

    Connections {
        target: Contact.ContactApplication

        function onCreateNewContact(): void {
            root.pageStack.pushDialogLayer(Qt.resolvedUrl("./private/contact_editor/ContactEditorPage.qml"), {
                mode: Contact.ContactEditor.CreateMode,
                initialCollectionId: Contact.ContactManager.selectedCollectionId(),
            });
        }

        function onCreateNewContactGroup(): void {
            root.pageStack.pushDialogLayer(Qt.resolvedUrl("./private/contact_editor/ContactGroupEditorPage.qml"), {
                mode: Contact.ContactGroupEditor.CreateMode,
                initialCollectionId: Contact.ContactManager.selectedCollectionId(),
            });
        }

        function onOpenSettings(): void {
            const openDialogWindow = root.pageStack.pushDialogLayer(Qt.createComponent("org.kde.merkuro.contact", "Settings"), {
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

    Connections {
        target: Contact.ContactManager

        function onErrorOccurred(error: string): void {
            root.showPassiveNotification(error);
        }
    }
}
