// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

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

    function test_createModeTitle() {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.CreateMode})
        verify(page)
        compare(page.title, "Add Contact")
    }

    function test_editModeTitle() {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.EditMode})
        verify(page)
        compare(page.title, "Edit Contact")
    }

    function test_emailAddButtonEnabledWhenTextEntered() {
        const page = createTemporaryObject(pageComponent, testCase)
        const emailField = findChild(page, "toAddEmailField")
        const addButton = findChild(page, "addEmailButton")
        verify(emailField)
        verify(addButton)
        compare(addButton.enabled, false)

        emailField.text = "ada@example.org"
        compare(addButton.enabled, true)
    }

    function test_phoneAddButtonEnabledWhenTextEntered() {
        const page = createTemporaryObject(pageComponent, testCase)
        const phoneField = findChild(page, "toAddPhoneField")
        const addButton = findChild(page, "addPhoneButton")
        verify(phoneField)
        verify(addButton)
        compare(addButton.enabled, false)

        phoneField.text = "+49 123 456"
        compare(addButton.enabled, true)
    }

    function test_instantMessengerFieldAcceptsInput() {
        const page = createTemporaryObject(pageComponent, testCase)
        const usernameField = findChild(page, "newUsernameField")
        verify(usernameField)

        usernameField.text = "ada"
        compare(usernameField.text, "ada")
    }

    function test_submitFlushesPendingEmailField() {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.CreateMode})
        page.contactEditor.contact.formattedName = "New Contact"

        const emailField = findChild(page, "toAddEmailField")
        emailField.text = "new@example.org"

        const submitAction = findChild(page, "submitAction")
        submitAction.trigger()

        compare(page.contactEditor.contact.emailModel.rowCount(), 1)
    }

    function test_itemChangedExternallyOpensDialog() {
        const page = createTemporaryObject(pageComponent, testCase, {mode: ContactEditor.EditMode})
        verify(!page.itemChangedExternallySheet.visible)

        page.contactEditor.itemChangedExternally()
        tryCompare(page.itemChangedExternallySheet, "visible", true)

        page.itemChangedExternallySheet.accept()
        tryCompare(page.itemChangedExternallySheet, "visible", false)
    }
}
