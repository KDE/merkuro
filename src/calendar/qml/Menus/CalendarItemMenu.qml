// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.components
import org.kde.akonadi as Akonadi

Components.ConvergentContextMenu {
    id: root

    required property var checkState
    required property var collectionId
    required property var collectionDetails
    required property Akonadi.AgentConfiguration agentConfiguration
	property bool allCollectionsChecked

    signal toggled
    signal showAllCollections(bool shown)

    headerContentItem: RowLayout {
        Kirigami.Heading {
            level: 2
            text: root.collectionDetails.displayName
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        ColoredCheckbox {
            id: collectionCheckbox

            implicitWidth: Kirigami.Units.gridUnit * 2
            implicitHeight: Kirigami.Units.gridUnit * 2

            visible: root.checkState !== undefined
            color: root.collectionDetails.color
            checked: root.checkState === 2
            onToggled: root.toggled();

            Layout.alignment: Qt.AlignVCenter
        }
    }

    Kirigami.Action {
        checkable: true
        checked: root.collectionDetails.isFiltered
        text: i18nc("@action:inmenu", "Display Events")
        visible: Kirigami.Settings.isMobile
        onTriggered: root.toggle()
    }

    QQC2.Action {
        icon.name: "edit-entry"
        text: i18nc("@action:inmenu", "Edit Calendar…")
        onTriggered: {
            let component = Qt.createComponent("org.kde.merkuro.calendar", "EditCalendarPage");
            pageStack.pushDialogLayer(component, {
                collection: Calendar.CalendarManager.getCollection(root.collectionId)
            }, {});
        }
    }

    Kirigami.Action {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update Calendar")
        onTriggered: Calendar.CalendarManager.updateCollection(root.collectionId);
        visible: !root.collectionDetails.isResource
    }

    QQC2.Action {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete Calendar")
        enabled: root.collectionDetails["canDelete"]
        onTriggered: () => {
            const dialogComponent = Qt.createComponent("qrc:/DeleteCalendarDialog.qml");
            if (dialogComponent.status !== Component.Ready) {
                console.error("Error:", dialogComponent.errorString());
                return;
            }

            const dialog = dialogComponent.createObject(applicationWindow(), {
                collectionId: root.collectionId,
                collectionDetails: root.collectionDetails
            });

            dialog.open();
        }
    }

    Kirigami.Action {
        separator: true
        visible: root.collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "settings-configure"
        text: i18nc("@action:inmenu", "Calendar source settings…")
        onTriggered: root.agentConfiguration.editIdentifier(root.collectionDetails.resource)
        visible: root.collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Update calendar source")
        onTriggered: root.agentConfiguration.restartIdentifier(root.collectionDetails.resource)
        visible: root.collectionDetails.isResource
    }

    Kirigami.Action {
        icon.name: "edit-delete"
        text: i18nc("@action:inmenu", "Delete calendar source")
        onTriggered: root.agentConfiguration.removeIdentifier(root.collectionDetails.resource)
        visible: root.collectionDetails.isResource
    }

    Kirigami.Action {
        separator: true
        visible: root.collectionDetails.isResource && !allCollectionsChecked
    }

    Kirigami.Action {
        icon.name: "view-visible"
        text: i18nc("@action:inmenu", "Show all")
        onTriggered: root.showAllCollections(true)
        visible: root.collectionDetails.isResource && !allCollectionsChecked
    }

    Kirigami.Action {
        icon.name: "view-hidden"
        text: i18nc("@action:inmenu", "Hide all")
        onTriggered: root.showAllCollections(false)
        visible: root.collectionDetails.isResource && allCollectionsChecked
    }
}
