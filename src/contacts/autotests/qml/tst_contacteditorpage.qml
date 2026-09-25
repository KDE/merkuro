// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest

import org.kde.merkuro.contact

TestCase {
    id: testCase
    name: "ContactEditorPageTest"
    when: windowShown
    width: 400
    height: 600

    readonly property var pageComponent: Qt.createComponent(Qt.resolvedUrl("../../qml/private/contact_editor/ContactEditorPage.qml"))
    readonly property var addressCardComponent: Qt.createComponent(Qt.resolvedUrl("../../qml/private/contact_editor/AddressEditorCard.qml"))
    readonly property var addressPageComponent: Qt.createComponent(Qt.resolvedUrl("../../qml/private/contact_editor/AddressEditorPage.qml"))

    function test_createModeTitle(): void {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.CreateMode})
        verify(page)
        compare(page.title, "Add Contact")
    }

    function test_createModeUsesInitialCollection(): void {
        const page = createTemporaryObject(pageComponent, testCase, {
            mode: ContactEditor.CreateMode,
            initialCollectionId: 42,
        })
        verify(page)

        const addressBookComboBox = findChild(page, "addressBookComboBox")
        verify(addressBookComboBox)
        compare(addressBookComboBox.defaultCollectionId, 42)
    }

    function test_createModeWithoutSelectedOrLastUsedCollection(): void {
        const previousCollectionId = ContactConfig.lastUsedAddressBookCollection
        ContactConfig.lastUsedAddressBookCollection = -1
        try {
            const page = createTemporaryObject(pageComponent, testCase, {
                mode: ContactEditor.CreateMode,
                initialCollectionId: -1,
            })
            verify(page)

            const addressBookComboBox = findChild(page, "addressBookComboBox")
            verify(addressBookComboBox)
            tryVerify(() => addressBookComboBox.currentValue > 0)
        } finally {
            ContactConfig.lastUsedAddressBookCollection = previousCollectionId
        }
    }

    function test_editModeTitle(): void {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.EditMode})
        verify(page)
        compare(page.title, "Edit Contact")
    }

    function test_emailAddButtonEnabledWhenTextEntered(): void {
        const page = createTemporaryObject(pageComponent, testCase)
        const emailField = findChild(page, "toAddEmailField")
        const addButton = findChild(page, "addEmailButton")
        verify(emailField)
        verify(addButton)
        compare(addButton.enabled, false)

        emailField.text = "ada@example.org"
        compare(addButton.enabled, true)
    }

    function test_phoneAddButtonEnabledWhenTextEntered(): void {
        const page = createTemporaryObject(pageComponent, testCase)
        const phoneField = findChild(page, "toAddPhoneField")
        const addButton = findChild(page, "addPhoneButton")
        verify(phoneField)
        verify(addButton)
        compare(addButton.enabled, false)

        phoneField.text = "+49 123 456"
        compare(addButton.enabled, true)
    }

    function test_instantMessengerFieldAcceptsInput(): void {
        const page = createTemporaryObject(pageComponent, testCase)
        const usernameField = findChild(page, "newUsernameField")
        verify(usernameField)

        usernameField.text = "ada"
        compare(usernameField.text, "ada")
    }

    function test_noteCanBeEdited(): void {
        const editorPage = createTemporaryObject(pageComponent, testCase)
        verify(editorPage)
        const noteField = findChild(editorPage, "contactNoteField")
        verify(noteField)
        compare(noteField.background, null)
        editorPage.contactEditor.contact.note = "Existing note"
        compare(noteField.text, "Existing note")
        noteField.text = "Met at the conference\nFollow up next week"
        compare(editorPage.contactEditor.contact.note, noteField.text)
        const noteScrollView = findChild(editorPage, "contactNoteScrollView")
        verify(noteScrollView)
        noteField.text = Array(40).fill("Long note").join("\n")
        verify(noteScrollView.contentHeight > noteScrollView.height)
        noteScrollView.contentItem.contentY = 50
        verify(noteScrollView.contentItem.contentY > 0)
        noteField.text = ""
        compare(editorPage.contactEditor.contact.note, "")
    }

    function test_addressPageAddsAndEditsAddresses(): void {
        const editorPage = createTemporaryObject(pageComponent, testCase)
        const model = editorPage.contactEditor.contact.addressesModel

        const firstPage = createTemporaryObject(addressPageComponent, testCase, {addressModel: model, row: -1})
        verify(firstPage)
        const firstStreetField = findChild(firstPage, "addressStreetField")
        const firstCityField = findChild(firstPage, "addressCityField")
        const firstSaveButton = findChild(firstPage, "saveAddressButton")
        verify(firstStreetField)
        verify(firstCityField)
        verify(firstSaveButton)
        const typeCombo = findChild(firstPage, "addressTypeCombo")
        verify(typeCombo)
        compare(typeCombo.count, 7)
        compare(typeCombo.currentValue, AddressModel.Home)
        typeCombo.activated(5)
        compare(typeCombo.currentValue, AddressModel.Work)
        compare(firstPage.hasAddressDetails, false)
        compare(firstSaveButton.enabled, false)
        firstStreetField.text = "First Street"
        firstCityField.text = "Berlin"
        compare(firstPage.hasAddressDetails, true)
        compare(firstSaveButton.enabled, true)
        firstPage.saveAddress()
        compare(model.rowCount(), 1)
        compare(model.addressAt(0).type, AddressModel.Work)

        const secondPage = createTemporaryObject(addressPageComponent, testCase, {addressModel: model, row: -1})
        verify(secondPage)
        findChild(secondPage, "addressStreetField").text = "Second Street"
        secondPage.saveAddress()
        compare(model.rowCount(), 2)

        const editPage = createTemporaryObject(addressPageComponent, testCase, {addressModel: model, row: 0})
        verify(editPage)
        const editStreetField = findChild(editPage, "addressStreetField")
        compare(editStreetField.text, "First Street")
        const editTypeCombo = findChild(editPage, "addressTypeCombo")
        compare(editTypeCombo.currentValue, AddressModel.Work)
        editTypeCombo.activated(4)
        editStreetField.text = "Updated Street"
        editPage.saveAddress()
        compare(model.data(model.index(0, 0), AddressModel.StreetRole), "Updated Street")
        compare(model.addressAt(0).type, AddressModel.Home)
        compare(model.data(model.index(1, 0), AddressModel.StreetRole), "Second Street")
    }

    function test_addressCardRequestsSelectedAddress(): void {
        const editorPage = createTemporaryObject(pageComponent, testCase)
        const model = editorPage.contactEditor.contact.addressesModel
        let address = model.addressAt(-1)
        address.street = "First Street"
        model.addAddress(address)

        const card = createTemporaryObject(addressCardComponent, testCase, {contactEditor: editorPage.contactEditor})
        verify(card)
        let requestedRow = -2
        card.addressRequested.connect(row => requestedRow = row)

        const addButton = findChild(card, "addAddressButton")
        const addressRow = findChild(card, "addressRow0")
        verify(addButton)
        verify(addressRow)
        addButton.clicked()
        compare(requestedRow, -1)
        addressRow.clicked()
        compare(requestedRow, 0)
    }

    function test_submitFlushesPendingEmailField(): void {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.CreateMode})
        page.contactEditor.contact.formattedName = "New Contact"

        const emailField = findChild(page, "toAddEmailField")
        emailField.text = "new@example.org"

        const submitAction = findChild(page, "submitAction")
        submitAction.trigger()

        compare(page.contactEditor.contact.emailModel.rowCount(), 1)
    }

    function test_itemChangedExternallyOpensDialog(): void {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.EditMode})
        verify(!page.itemChangedExternallySheet.visible)

        page.contactEditor.itemChangedExternally()
        tryCompare(page.itemChangedExternallySheet, "visible", true)

        page.itemChangedExternallySheet.accept()
        tryCompare(page.itemChangedExternallySheet, "visible", false)
    }
}
