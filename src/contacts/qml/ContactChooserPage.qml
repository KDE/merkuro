// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.contact
import org.kde.merkuro.components as Components
import org.kde.akonadi as Akonadi
import './private'

ContactsPage {
    id: root

    signal addAttendee(int itemId, string email)
    signal removeAttendee(int itemId)

    required property list<int> attendeeAkonadiIds

    function removeAttendeeByItemId(deletedItemId: int): void {
        for (let i = 0, count = root.model.rowCount(); i < count; i++) {
            const itemId = root.model.data(root.model.index(i, 0), Akonadi.EntityTreeModel.ItemIdRole);
            if (itemId === deletedItemId) {
                root.selectionModel.select(root.model.index(i, 0), ItemSelectionModel.Deselect);
                break;
            }
        }
    }

    actions: Kirigami.Action {
        icon.name: "object-select-symbolic"
        text: i18n("Done")
        onTriggered: pageStack.pop()
    }

    selectionModel {
        onSelectionChanged: (selected, deselected) => {
            for (let selectedIndex of Components.Utils.indexesFromSelection(selected)) {
                const allEmail = root.model.data(selectedIndex, ContactsModel.AllEmailsRole);
                const itemId = root.model.data(selectedIndex, Akonadi.EntityTreeModel.ItemIdRole);
                if (root.attendeeAkonadiIds.includes(itemId)) {
                    continue;
                }
                if (allEmail.length > 1) {
                    emailsView.model = allEmail;
                    emailsView.itemId = itemId;
                    emailPickerSheet.open();
                } else if(allEmail.length === 1) {
                    root.addAttendee(itemId, allEmail[0])
                } else {
                    root.addAttendee(itemId, undefined)
                }
            }

            for (let deselectedIndex of Components.Utils.indexesFromSelection(deselected)) {
                const itemId = root.model.data(deselectedIndex, Akonadi.EntityTreeModel.ItemIdRole);
                root.removeAttendee(itemId);
            }
        }
    }

    Component.onCompleted: {
        for (let i = 0, count = root.model.rowCount(); i < count; i++) {
            const itemId = root.model.data(root.model.index(i, 0), Akonadi.EntityTreeModel.ItemIdRole);
            if (root.attendeeAkonadiIds.includes(model.itemId)) {
                root.selectionModel.select(root.model.index(i, 0), ItemSelectionModel.Select);
            }
        }
    }

    contactDelegate: ContactListItem {
        id: delegate

        selectionModel: root.selectionModel

        onClicked: {
            root.selectionModel.select(root.selectionModel.model.index(delegate.index, 0), ItemSelectionModel.Toggle);
        }
    }

    Kirigami.OverlaySheet {
        id: emailPickerSheet

        header: Kirigami.Heading {
            text: i18n("Select Email Address")
        }

        ListView {
            id: emailsView
            property int itemId

            implicitWidth: Kirigami.Units.gridUnit * 30
            model: []

            delegate: Delegates.RoundedItemDelegate {
                required property var modelData

                text: modelData
                onClicked: {
                    root.addAttendee(emailsView.itemId, modelData);
                    emailPickerSheet.close();
                }
            }
        }
    }

}
