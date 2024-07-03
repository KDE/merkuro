// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

QQC2.Menu {
    id: actionsPopup
    z: 1000

    required property var collectionId
    required property var collectionDetails
    required property Akonadi.AgentConfiguration agentConfiguration

    QQC2.MenuItem {
        icon.name: "edit-entry"
        text: i18nc("@action:inmenu", "Edit calendar…")
        onClicked: Calendar.CalendarManager.editCollection(actionsPopup.collectionId);
    }

    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar")
        onClicked: Calendar.CalendarManager.updateCollection(actionsPopup.collectionId);
    }

    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar")
        enabled: actionsPopup.collectionDetails["canDelete"]
        onClicked: () => {
            const dialogComponent = Qt.createComponent("qrc:/DeleteCalendarDialog.qml");
            if (dialogComponent.status !== Component.Ready) {
                console.error("Error:", dialogComponent.errorString());
                return;
            }

            const dialog = dialogComponent.createObject(applicationWindow(), {
                collectionId: actionsPopup.collectionId,
                collectionDetails: actionsPopup.collectionDetails
            });

            dialog.open();
        }

    }
    QQC2.MenuSeparator {
    }
    QQC2.MenuItem {
        icon.name: "color-picker"
        text: i18nc("@action:inmenu", "Set calendar colour…")
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
        text: i18nc("@action:inmenu", "Calendar source settings…")
        onClicked: actionsPopup.agentConfiguration.editIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar source")
        onClicked: actionsPopup.agentConfiguration.restartIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar source")
        onClicked: actionsPopup.agentConfiguration.removeIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
}
