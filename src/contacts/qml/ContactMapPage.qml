// SPDX-FileCopyrightText: 2019-2023 Volker Krause <vkrause@kde.org>
// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtLocation
import QtPositioning
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.contacts as Contacts
import org.kde.merkuro.contact
import org.kde.ki18n

Kirigami.Page {
    id: root
    objectName: "contactMapPage"

    title: KI18n.i18nc("@title:window", "Contacts Map")
    padding: 0
    Kirigami.ColumnView.preventStealing: true
    Kirigami.ColumnView.fillWidth: true
    Kirigami.ColumnView.reservedSpace: Kirigami.Units.gridUnit * 20

    readonly property Kirigami.PageRow pageStack: Kirigami.PageStack.pageStack as Kirigami.PageRow
    property var contactsModel: ContactMapModel {
        sourceModel: ContactsModel {}
    }
    property Plugin mapPlugin: Plugin {
        name: "osm"
        PluginParameter {
            name: "osm.useragent"
            value: Application.name + "/" + Application.version + " (kde-pim@kde.org)"
        }
        PluginParameter {
            name: "osm.mapping.providersrepository.address"
            value: "https://autoconfig.kde.org/qtlocation/"
        }
    }

    actions: [
        Kirigami.Action {
            text: KI18n.i18nc("@action:button", "Show All Contacts")
            icon.name: "zoom-fit-best"
            enabled: root.contactsModel.count > 0
            onTriggered: map.fitViewportToMapItems()
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action:button", "Zoom In")
            icon.name: "zoom-in"
            shortcut: StandardKey.ZoomIn
            enabled: map.zoomLevel < map.maximumZoomLevel
            onTriggered: map.zoomLevel = Math.min(map.zoomLevel + 1, map.maximumZoomLevel)
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action:button", "Zoom Out")
            icon.name: "zoom-out"
            shortcut: StandardKey.ZoomOut
            enabled: map.zoomLevel > map.minimumZoomLevel
            onTriggered: map.zoomLevel = Math.max(map.zoomLevel - 1, map.minimumZoomLevel)
        }
    ]

    Map {
        id: map
        objectName: "contactsMap"

        anchors.fill: parent
        zoomLevel: 2
        plugin: root.mapPlugin

        onCopyrightLinkActivated: function (link: string): void {
            Qt.openUrlExternally(link);
        }

        DragHandler {
            target: null
            onTranslationChanged: function (delta: vector2d): void {
                map.pan(-delta.x, -delta.y);
            }
        }

        PinchHandler {
            id: pinch
            target: null
            property geoCoordinate startCoordinate
            xAxis.enabled: false
            yAxis.enabled: false
            minimumRotation: 0
            maximumRotation: 0
            onActiveChanged: {
                if (active) {
                    startCoordinate = map.toCoordinate(pinch.centroid.position, false);
                }
            }
            onScaleChanged: function (delta: real): void {
                map.zoomLevel = Math.max(map.minimumZoomLevel, Math.min(map.zoomLevel + Math.log2(delta), map.maximumZoomLevel));
                map.alignCoordinateToPoint(pinch.startCoordinate, pinch.centroid.position);
            }
        }

        WheelHandler {
            id: wheel
            target: null
            rotationScale: 1 / 120
            orientation: Qt.Vertical
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function (event: WheelEvent): void {
                const coordinate = map.toCoordinate(wheel.point.position, false);
                map.zoomLevel = Math.max(map.minimumZoomLevel, Math.min(map.zoomLevel + event.angleDelta.y * wheel.rotationScale, map.maximumZoomLevel));
                map.alignCoordinateToPoint(coordinate, wheel.point.position);
            }
        }

        MapItemView {
            id: markers
            objectName: "contactMarkers"

            model: root.contactsModel
            autoFitViewport: true

            delegate: MapQuickItem {
                id: marker

                required property geoCoordinate contactCoordinate
                required property string fullName
                required property int gid
                required property Contacts.addressee addressee

                coordinate: marker.contactCoordinate
                anchorPoint.x: markerButton.width / 2
                anchorPoint.y: markerButton.height

                sourceItem: Components.AvatarButton {
                    id: markerButton
                    name: marker.fullName.trim().length > 0 ? marker.fullName : KI18n.i18nc("@info:placeholder", "No name")
                    sourceSize.width: Kirigami.Units.iconSizes.large
                    sourceSize.height: Kirigami.Units.iconSizes.large
                    asynchronous: true
                    source: {
                        if (!marker.addressee.photo.isEmpty) {
                            return marker.addressee.photo.isIntern ? "image://avatar/" + marker.gid : marker.addressee.photo.url;
                        }
                        return marker.addressee.preferredEmail.length > 0 ? "image://contact/" + marker.addressee.preferredEmail : "";
                    }
                    onClicked: root.pageStack.push(Qt.resolvedUrl("./private/ContactPage.qml"), {
                        itemId: marker.gid
                    })
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: root.contactsModel.count === 0
        objectName: "noLocationsPlaceholder"
        text: KI18n.i18nc("@info:placeholder", "No contacts with location information")
        explanation: KI18n.i18nc("@info:placeholder", "Contacts with geographic coordinates will appear here.")
    }

    QQC2.Label {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: Kirigami.Units.largeSpacing
        }
        visible: map.error !== Map.NoError
        text: map.errorString
        wrapMode: Text.Wrap
        width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 24)
    }
}
