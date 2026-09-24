/*
 * SPDX-FileCopyrightText: 2017-2019 Kaidan Developers and Contributors 
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.kirigamiaddons.labs.components as KAComponents
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.components
import org.kde.akonadi as Akonadi
import org.kde.contacts as Contacts
import org.kde.ki18n

Delegates.RoundedItemDelegate {
    id: root
    required property int index
    required property int itemId
    required property string displayName
    required property string mimeType
    required property var model
    required property Contacts.addressee addressee
    required property Akonadi.item item
    required property var decoration
    required property ItemSelectionModel selectionModel
    property bool dragEnabled: false

    signal createContextMenu

    function moveToCollection(collection: var): void {
        ContactManager.moveItemToCollection(root.item, collection);
    }

    text: model.display.trim().length > 0 ? model.display : KI18n.i18nc("@info:placeholder", "No name")

    onPressAndHold: {
        root.selectionModel.clearCurrentIndex();
        root.selectionModel.select(root.selectionModel.model.index(root.index, 0), ItemSelectionModel.Toggle);
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        ColoredCheckbox {
            id: checkbox
            visible: root.selectionModel.hasSelection
            onToggled: {
                root.selectionModel.select(root.selectionModel.model.index(root.index, 0), ItemSelectionModel.Toggle)
            }

            Binding {
                target: checkbox
                property: 'checked'
                value: root.selectionModel.selectedIndexes.includes(root.selectionModel.model.index(root.index, 0))
            }

            indicator {
                implicitWidth: Kirigami.Units.gridUnit
                implicitHeight: Kirigami.Units.gridUnit
            }

            topPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing
        }

        KAComponents.Avatar {
            id: avatar

            name: root.text
            sourceSize.width: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            sourceSize.height: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            Layout.preferredWidth: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing * 2

            source: {
                if (!root.addressee.photo.isEmpty) {
                    return root.addressee.photo.isIntern ? "image://avatar/" + root.itemId : root.addressee.photo.url
                } else if (root.mimeType === Akonadi.MimeTypes.address && root.addressee.preferredEmail.length > 0) {
                    return "image://contact/" + root.addressee.preferredEmail
                }
                return ""
            }

            Accessible.ignored: true // same as name
        }

        Kirigami.Heading {
            text: root.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            level: 3
            Layout.fillWidth: true
            Accessible.ignored: true // already exposed in root
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.createContextMenu()
    }

    states: State {
        when: root.Drag.active
        ParentChange {
            target: root
            parent: root.QQC2.Overlay.overlay
        }
    }

    DragHandler {
        id: dragHandler
        enabled: root.dragEnabled && !Kirigami.Settings.isMobile && root.mimeType === Akonadi.MimeTypes.address
        cursorShape: Qt.DragMoveCursor
        onActiveChanged: {
            root.down = false;
            if (!active) {
                root.Drag.drop();
            }
        }
    }

    Drag.active: dragHandler.active
    Drag.supportedActions: Qt.MoveAction
    Drag.hotSpot.x: root.width / 2
    Drag.hotSpot.y: root.height / 2
}
