// SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates 1 as Delegates

Kirigami.OverlaySheet {

    id: root

    property alias numbers: list.model
    property alias title: heading.text

    signal numberSelected(string number)

    header: Kirigami.Heading {
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
                close();
                root.numberSelected(modelData.normalizedNumber);
            }
        }
    }
}
