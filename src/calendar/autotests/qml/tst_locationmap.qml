// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import QtPositioning
import org.kde.merkuro.calendar as Calendar

TestCase {
    id: testCase
    name: "LocationMapTest"
    when: windowShown
    visible: true
    width: 500
    height: 500

    Component {
        id: mapComponent
        Calendar.LocationMap {
            pluginComponent.name: ""
            query: ""
        }
    }

    Component {
        id: locationComponent
        Location {
            coordinate: QtPositioning.coordinate(52.47, 13.4)
            boundingShape: QtPositioning.rectangle(QtPositioning.coordinate(52.48, 13.39), QtPositioning.coordinate(52.46, 13.41))
        }
    }

    function test_markerLocation_data(): list<var> {
        return [{ tag: "pin", marker: "pin" }, { tag: "circle", marker: "circle" }];
    }

    function test_markerLocation(data: var): void {
        failOnWarning(/.*(TypeError|ReferenceError).*/);
        const map = createTemporaryObject(mapComponent, testCase);
        verify(map);
        const markers = findChild(map, "locationMarkers");
        verify(markers);
        const marker = createTemporaryObject(markers[data.marker], map, { locationData: null });
        verify(marker);
        compare(marker.visible, false);

        const location = createTemporaryObject(locationComponent, testCase);
        verify(location);
        marker.locationData = location;
        compare(marker.visible, true);
        const coordinate = data.marker === "pin" ? marker.coordinate : marker.center;
        compare(coordinate.latitude, location.coordinate.latitude);
        compare(coordinate.longitude, location.coordinate.longitude);
        if (data.marker === "circle") {
            const bounds = location.boundingShape.boundingGeoRectangle();
            const expectedRadius = bounds.center.distanceTo(bounds.topRight);
            verify(expectedRadius > 0);
            tryCompare(marker, "radius", expectedRadius);
        }

        marker.locationData = null;
        compare(marker.visible, false);
    }
}
