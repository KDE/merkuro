// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

Components.ContextMenu {
    id: actionsPopup
    z: 1000

    required property var collectionId
    required property var collectionDetails
    required property Akonadi.AgentConfiguration agentConfiguration

    QQC2.Action {
        icon.name: "edit-entry"
        text: i18nc("@action:inmenu", "Edit calendar…")
        onTriggered: Calendar.CalendarManager.editCollection(actionsPopup.collectionId);
    }

    QQC2.Action {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar")
        onTriggered: Calendar.CalendarManager.updateCollection(actionsPopup.collectionId);
    }

    QQC2.Action {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar")
        enabled: actionsPopup.collectionDetails["canDelete"]
        onTriggered: () => {
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

    Kirigami.Action {
        separator: true
    }

    QQC2.Action {
        icon.name: "color-picker"
        text: i18nc("@action:inmenu", "Set calendar colour…")
        onTriggered: {
            colorDialogLoader.active = true;
            colorDialogLoader.item.open();
        }
    }

    Kirigami.Action {
        separator: true
        visible: collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "settings-configure"
        text: i18nc("@action:inmenu", "Calendar source settings…")
        onTriggered: actionsPopup.agentConfiguration.editIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar source")
        onTriggered: actionsPopup.agentConfiguration.restartIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar source")
        onTriggered: actionsPopup.agentConfiguration.removeIdentifier(collectionDetails.resource)
        visible: collectionDetails.isResource
    }
}
