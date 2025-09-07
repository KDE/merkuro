// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma Singleton

import QtQuick
import org.kde.kirigamiaddons.dateandtime
import org.kde.kirigami as Kirigami

/// A sinple singleton to share the instance of this popup across the whole app.
QtObject {
    id: root

    property alias value: popup.value
    property alias x: popup.x
    property alias y: popup.y
    property alias visible: popup.visible
    property alias popupParent: popup.parent

    signal accepted()
    signal opened()
    signal closed()

    function open() {
        popup.open();
    }

    function close() {
        popup.close();
    }

    property DatePopup popup: DatePopup {
        id: popup
        implicitWidth: Kirigami.Units.gridUnit * 20
        autoAccept: true
        onAccepted: root.accepted();
        onClosed: root.closed();
        onOpened: root.opened();
    }
}
