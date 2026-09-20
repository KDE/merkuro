// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import org.kde.ki18n

QQC2.Menu {
    id: actionsPopup
    z: 1000

    required property var collection
    required property var collectionDetails
    required property Akonadi.AgentConfiguration agentConfiguration

    QQC2.MenuItem {
        icon.name: "edit-entry"
        text: KI18n.i18nc("@action:inmenu", "Edit address book…")
        onClicked: {
            const component = Qt.createComponent("org.kde.merkuro.components", "EditCollectionPage");
            QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                title: KI18n.i18nc("@title", "Edit Address Book"),
                collection: actionsPopup.collection,
            }, {});
        }
    }
    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: KI18n.i18nc("@action:inmenu", "Update address book")
        onClicked: ContactManager.updateCollection(actionsPopup.collection);
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: KI18n.i18nc("@action:inmenu", "Delete address book")
        enabled: actionsPopup.collectionDetails.canDelete
        onClicked: ContactManager.deleteCollection(actionsPopup.collection)
    }
    QQC2.MenuSeparator {
    }
    QQC2.MenuItem {
        icon.name: "color-picker"
        text: KI18n.i18nc("@action:inmenu", "Set address book color…")
        onClicked: {
            colorDialogLoader.active = true;
            colorDialogLoader.item.open();
        }
    }
    QQC2.MenuSeparator {
        visible: collectionDetails.isResource
    }

    QQC2.MenuItem {
        icon.name: "settings-configure"
        text: KI18n.i18nc("@action:inmenu", "Address book source settings…")
        onClicked: actionsPopup.agentConfiguration.editIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: KI18n.i18nc("@action:inmenu", "Update address book source")
        onClicked: actionsPopup.agentConfiguration.restartIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: KI18n.i18nc("@action:inmenu", "Delete address source")
        onClicked: actionsPopup.agentConfiguration.removeIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
}
