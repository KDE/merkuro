/*
 * SPDX-FileCopyrightText: 2017-2019 Kaidan Developers and Contributors 
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.labs.components 1.0 as KAComponents
import org.kde.kirigamiaddons.delegates as Delegates

Delegates.RoundedItemDelegate {
    id: listItem

    property string name
    property bool added: false
    property var avatarIcon

    signal createContextMenu

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        KAComponents.Avatar {
            id: avatar
            Layout.maximumHeight: parent.height
            Layout.maximumWidth: parent.height
            source: ContactManager.decorationToUrl(avatarIcon)
            name: listItem.name
        }

        Kirigami.Heading {
            text: name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            level: Kirigami.Settings.isMobile ? 3 : 0
            Layout.fillWidth: true
        }

        Kirigami.Icon {
            height: parent.height
            width: height
            source: "checkmark"
            visible: added
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: listItem.createContextMenu()
        }
    }
}
