// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtTest

import org.kde.merkuro.contact

TestCase {
    id: testCase
    name: "ContactViewQmlTest"

    Component {
        id: contactViewComponent
        ContactView {}
    }

    AddresseeWrapper {
        id: testContact
        formattedName: "Ada Lovelace"
    }

    ListModel {
        id: contactsModel
    }

    function init() {
        contactsModel.clear()
    }

    function test_viewProperties() {
        const view = createTemporaryObject(contactViewComponent, testCase)
        verify(view)
        compare(view.objectName, "contactView")
        compare(view.title, "Contacts")
        compare(view.actions.length, 1)
        compare(view.actions[0].text, "Create")
    }

    function test_emptyStateIsDisplayed() {
        const view = createTemporaryObject(contactViewComponent, testCase)
        verify(view)

        const contactsList = findChild(view, "contactsList")
        verify(contactsList)
        compare(contactsList.count, 0)

        const placeholder = findChild(view, "noContactsPlaceholder")
        verify(placeholder)
    }

    function test_nonEmptyStateAndContextMenu() {
        contactsModel.append({
            display: "Ada Lovelace",
            displayName: "Ada Lovelace",
            itemId: 1,
            mimeType: "text/directory",
            addressee: testContact,
            item: ContactManager.getItem(1),
            decoration: "",
        })

        const view = createTemporaryObject(contactViewComponent, testCase, {
            contactsModel: contactsModel,
            width: 400,
            height: 400,
        })
        verify(view)

        const contactsList = findChild(view, "contactsList")
        verify(contactsList)
        tryCompare(contactsList, "count", 1)

        const delegate = findChild(view, "contactListItem")
        verify(delegate)
        view.showContextMenu(0)

        const menu = view.activeContextMenu
        verify(menu)
        compare(menu.objectName, "contactContextMenu")
        compare(menu.actions.length, 4)
    }
}
