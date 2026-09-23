// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.purpose as Purpose
import org.kde.ki18n

Kirigami.Action {
    id: root

    required property Kirigami.ApplicationWindow application
    required property ContactImportExport exporter
    required property int itemId

    property string contactUrl: ""
    property var inputData: root.contactUrl ? ({
        urls: [root.contactUrl],
        mimeType: ["text/vcard"],
    }) : ({})

    text: KI18n.i18nc("@action:inmenu", "Share Contact")
    icon.name: "emblem-shared-symbolic"
    tooltip: KI18n.i18nc("@tooltip", "Share this contact")
    visible: false

    Component.onCompleted: root.exporter.prepareContactForSharing(root.itemId)

    property Connections _exporterConnection: Connections {
        target: root.exporter

        function onContactReadyToShare(url: url): void {
            root.contactUrl = url.toString();
            root.visible = true;
        }
    }

    property Instantiator _instantiator: Instantiator {
        id: alternatives

        model: Purpose.PurposeAlternativesModel {
            pluginType: "Export"
            inputData: root.inputData
        }
        delegate: Kirigami.Action {
            required property int index
            required property string iconName
            required property string actionDisplay

            text: actionDisplay
            icon.name: iconName
            onTriggered: root.application.pageStack.pushDialogLayer(Qt.createComponent("./ContactShareDialog.qml"), {
                title: root.tooltip,
                index,
                model: alternatives.model,
                application: root.application,
            })
        }

        onObjectAdded: (index, object) => {
            object.index = index;
            root.children.push(object);
        }
        onObjectRemoved: (index, object) => root.children = Array.from(root.children).filter(action => action.pluginId !== object.pluginId)
    }
}
