// SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.OverlaySheet {

    id: root

    property alias numbers: list.model
    signal numberSelected(string number)

    header: Kirigami.Heading {
        text: root.title
        id: heading
    }

    ListView {
        id: list
        implicitWidth: Kirigami.Units.gridUnit * 20
        model: 4
        delegate: Delegates.RoundedItemDelegate {
            id: contactDelegate

            required property var modelData

            text: modelData.typeLabel
            contentItem: Delegates.SubtitleContentItem {
                itemDelegate: contactDelegate
                subtitle: contactDelegate.modelData.number
            }

            onClicked: {
                root.close();
                root.numberSelected(contactDelegate.modelData.normalizedNumber);
            }
        }
    }
}
