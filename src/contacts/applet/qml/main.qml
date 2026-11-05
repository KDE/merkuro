// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.ksvg as KSvg
import org.kde.merkuro.contact
import org.kde.ki18n

PlasmoidItem {
    id: contactApplet

    width: Kirigami.Units.gridUnit * 24
    height: Kirigami.Units.gridUnit * 30

    Plasmoid.icon: 'im-user-symbolic'

    switchWidth: Kirigami.Units.gridUnit * 5
    switchHeight: Kirigami.Units.gridUnit * 5

    Component.onCompleted: AvatarImageProvider.init()

    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30
        collapseMarginsHint: true

        focus: true

        header: stack.currentItem ? stack.currentItem.header : null

        property string itemTitle: stack.currentItem ? stack.currentItem.title : ""
        onItemTitleChanged: contactApplet.Plasmoid.title = itemTitle ?? KI18n.i18n("Contact")

        property alias listMargins: listItemSvg.margins

        KSvg.FrameSvgItem {
            id : listItemSvg
            imagePath: "widgets/listitem"
            prefix: "normal"
            visible: false
        }

        Keys.forwardTo: [stack.currentItem]

        QQC2.StackView {
            id: stack
            anchors.fill: parent
            initialItem: ContactsPage {}
        }
    }
}
