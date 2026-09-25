// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest

import org.kde.merkuro.contact

TestCase {
    id: testCase
    name: "ContactGroupEditorPageTest"
    when: windowShown
    width: 400
    height: 600

    readonly property Component pageComponent: Qt.createComponent(Qt.resolvedUrl("../../qml/private/contact_editor/ContactGroupEditorPage.qml"))

    function test_createModeUsesInitialCollection(): void {
        const page = createTemporaryObject(pageComponent, testCase, {
            mode: ContactGroupEditor.CreateMode,
            initialCollectionId: 42,
        })
        verify(page)

        const addressBookComboBox = findChild(page, "groupAddressBookComboBox")
        verify(addressBookComboBox)
        compare(addressBookComboBox.defaultCollectionId, 42)
    }

    function test_createModeWithoutSelectedOrLastUsedCollection(): void {
        const previousCollectionId = ContactConfig.lastUsedAddressBookCollection
        ContactConfig.lastUsedAddressBookCollection = -1
        try {
            const page = createTemporaryObject(pageComponent, testCase, {
                mode: ContactGroupEditor.CreateMode,
                initialCollectionId: -1,
            })
            verify(page)

            const addressBookComboBox = findChild(page, "groupAddressBookComboBox")
            verify(addressBookComboBox)
            tryVerify(() => addressBookComboBox.currentValue > 0)
        } finally {
            ContactConfig.lastUsedAddressBookCollection = previousCollectionId
        }
    }
}
