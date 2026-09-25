// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.contact
import org.kde.ki18n

Kirigami.ScrollablePage {
    id: page

    property int itemId
    readonly property Kirigami.ApplicationWindow appWindow: page.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow
    readonly property Kirigami.PageRow pageStack: page.appWindow.pageStack as Kirigami.PageRow
    property ContactGroupWrapper contactGroup: ContactGroupWrapper {
        id: contactGroup
        item: ContactManager.getItem(page.itemId)
    }

    title: contactGroup.name

    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    function openEditor() {
        const editor = page.pageStack.pushDialogLayer(Qt.resolvedUrl("contact_editor/ContactGroupEditorPage.qml"), {
            mode: ContactGroupEditor.EditMode,
        });
        editor.item = page.contactGroup.item;
    }

    actions: Kirigami.Action {
        icon.name: "document-edit"
        text: KI18n.i18nc("@action:button", "Edit")
        onTriggered: page.openEditor()
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
