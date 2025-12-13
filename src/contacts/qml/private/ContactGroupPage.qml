// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.contact

Kirigami.ScrollablePage {
    id: page

    property int itemId
    property ContactGroupWrapper contactGroup: ContactGroupWrapper {
        id: contactGroup
        item: ContactManager.getItem(page.itemId)
    }

    title: contactGroup.name

    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    function openEditor() {
        const editor = pageStack.pushDialogLayer(Qt.resolvedUrl("contact_editor/ContactGroupEditorPage.qml"), {
            mode: ContactGroupEditor.EditMode,
        });
        editor.item = page.contactGroup.item;
    }

    actions: Kirigami.Action {
        icon.name: "document-edit"
        text: i18nc("@action:button", "Edit")
        onTriggered: openEditor()
    }

    ListView {
        model: contactGroup.model
        delegate: Delegates.RoundedItemDelegate {
            id: contact

            required property int index
            required property string iconName
            required property string email
            required property string displayName

            icon.name: iconName
            text: displayName

            contentItem: Delegates.SubtitleContentItem {
                itemDelegate: contact
                subtitle: contact.email
            }
        }
    }
}
