// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar

Map {
    id: map
    anchors.fill: parent

    signal selectedLocationAddress(string address)

    property alias pluginComponent: mapPlugin
    property var query
    property real selectedLatitude: NaN
    property real selectedLongitude: NaN
    readonly property bool hasCoordinate: !isNaN(selectedLatitude) && !isNaN(selectedLongitude)
    property bool queryHasResults: geocodeModel.count > 0
    property int queryStatus: geocodeModel.status
    property bool containsLocation: {
        const location = queryHasResults ? geocodeModel.get(0) : null;
        return location ? visibleRegion.contains(location.coordinate) : false;
    }
    property bool selectMode: false

    function goToLocation(): void {
        const location = geocodeModel.count > 0 ? geocodeModel.get(0) : null;
        if (!location) {
            return;
        }
        map.fitViewportToGeoShape(location.boundingShape, 0);
        if (map.zoomLevel > 18.0) {
            map.zoomLevel = 18.0;
        }
    }

    plugin: Plugin {
        id: mapPlugin
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
    onCopyrightLinkActivated: link => Qt.openUrlExternally(link)

    BusyIndicator {
        anchors.centerIn: parent
        running: map.queryStatus === GeocodeModel.Loading
        visible: map.queryStatus === GeocodeModel.Loading
    }

    Button {
        anchors.right: parent.right
        text: i18n("Return to Location")
        visible: !map.containsLocation && map.query
        onClicked: map.goToLocation()
        z: 10
    }

    MapItemView {
        objectName: "locationMarkers"

        MouseArea {
            anchors.fill: parent
            enabled: map.selectMode
            onClicked: {
                var coords = map.toCoordinate(Qt.point(mouseX, mouseY), false);
                clickGeocodeModel.query = coords;
                clickGeocodeModel.update();
            }

            GeocodeModel {
                id: clickGeocodeModel
                plugin: map.pluginComponent
                limit: 1
                onLocationsChanged: if(count) { map.selectedLocationAddress(get(0).address.text) }
            }
        }

        model: GeocodeModel {
            id: geocodeModel
            plugin: map.pluginComponent
            query: map.hasCoordinate ? undefined : map.query
            autoUpdate: true
            limit: 1
            onLocationsChanged: {
                if(count > 0) {
                    map.goToLocation();
                }
            }
        }

        property Component circle: MapCircle {
            id: mapCircle
            required property Location locationData

            visible: mapCircle.locationData !== null
            radius: {
                if (!mapCircle.locationData) {
                    return 0;
                }
                const bounds = mapCircle.locationData.boundingShape.boundingGeoRectangle();
                return bounds.center.distanceTo(bounds.topRight);
            }
            color: Kirigami.Theme.highlightColor
            border.color: Kirigami.Theme.linkColor
            border.width: 2
            smooth: true
            opacity: 0.25
            center: mapCircle.locationData ? mapCircle.locationData.coordinate : QtPositioning.coordinate()
        }

        property Component pin: MapQuickItem {
            id: mapPin
            required property Location locationData

            visible: mapPin.locationData !== null
            coordinate: mapPin.locationData ? mapPin.locationData.coordinate : QtPositioning.coordinate()
            anchorPoint.x: iconMarker.width/2
            anchorPoint.y: iconMarker.height

            sourceItem: Kirigami.Icon {
                id: iconMarker
                isMask: true
                color: Kirigami.Theme.negativeTextColor // Easier to see
                source: "mark-location"
            }
        }

        delegate: switch(Config.locationMarker) {
            case Config.Circle:
                return circle;
            case Config.Pin:
            default:
                return pin;
        }
    }

    Component.onCompleted: {
        if (hasCoordinate) {
            map.center = QtPositioning.coordinate(selectedLatitude, selectedLongitude);
            map.zoomLevel = 17.0;
        }
    }
}
