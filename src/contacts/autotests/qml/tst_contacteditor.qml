// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtTest

import org.kde.merkuro.contact

TestCase {
    id: testCase
    name: "ContactEditorQmlTest"

    ContactEditor {
        id: editor
        mode: ContactEditor.CreateMode
    }

    ContactEditor {
        id: existingContactEditor
        mode: ContactEditor.EditMode
    }

    SignalSpy {
        id: saveSpy
        target: existingContactEditor
        signalName: "finished"
    }

    SignalSpy {
        id: saveErrorSpy
        target: existingContactEditor
        signalName: "errorOccured"
    }

    SignalSpy {
        id: itemFetchSpy
        target: contactTestItemProvider
        signalName: "itemChanged"
    }

    SignalSpy {
        id: itemFetchErrorSpy
        target: contactTestItemProvider
        signalName: "errorOccurred"
    }

    SignalSpy {
        id: itemChangedExternallySpy
        target: existingContactEditor
        signalName: "itemChangedExternally"
    }

    Text {
        id: nameBinding
        text: editor.contact.formattedName
    }

    function init() {
        editor.contact.formattedName = ""
        while (editor.contact.emailModel.rowCount() > 0) {
            editor.contact.emailModel.deleteEmail(0)
        }
        while (editor.contact.phoneModel.rowCount() > 0) {
            editor.contact.phoneModel.deletePhoneNumber(0)
        }
    }

    function test_contactPropertyBinding() {
        editor.contact.formattedName = "Ada Lovelace"
        compare(nameBinding.text, "Ada Lovelace")

        editor.contact.formattedName = "Grace Hopper"
        tryCompare(nameBinding, "text", "Grace Hopper")
    }

    function test_emailModelIsUsableFromQml() {
        compare(editor.contact.emailModel.rowCount(), 0)

        editor.contact.emailModel.addEmail("ada@example.org", EmailModel.Work)

        compare(editor.contact.emailModel.rowCount(), 1)
        compare(editor.contact.emailModel.data(editor.contact.emailModel.index(0, 0), Qt.DisplayRole), "ada@example.org")
    }

    function test_phoneModelIsUsableFromQml() {
        editor.contact.phoneModel.addPhoneNumber("+49 123 456", PhoneModel.Cell)

        compare(editor.contact.phoneModel.rowCount(), 1)
        compare(editor.contact.phoneModel.data(editor.contact.phoneModel.index(0, 0), Qt.DisplayRole), "+49 123 456")
    }

    function test_createEditorState() {
        compare(editor.mode, ContactEditor.CreateMode)
        compare(editor.isReadOnly, false)
        compare(editor.saving, false)
    }

    function test_editAndSaveExistingContact() {
        itemFetchSpy.wait(5000)
        compare(itemFetchErrorSpy.count, 0)
        existingContactEditor.item = contactTestItemProvider.item
        tryCompare(existingContactEditor.contact, "formattedName", "QML Editor Test Contact")
        tryCompare(existingContactEditor, "isReadOnly", false)

        existingContactEditor.contact.note = "Updated by the QML editor test"
        existingContactEditor.saveContactInAddressBook()

        saveSpy.wait(5000)
        compare(saveErrorSpy.count, 0)
        compare(existingContactEditor.saving, false)
        compare(existingContactEditor.contact.note, "Updated by the QML editor test")
    }

    // Regression test for m_item revision going stale after an external change.
    function test_itemChangedExternallyKeepsItemRevisionInSync() {
        existingContactEditor.contact.formattedName = ""
        existingContactEditor.item = contactTestItemProvider.item
        tryCompare(existingContactEditor.contact, "formattedName", "QML Editor Test Contact")

        itemChangedExternallySpy.clear()
        contactTestItemProvider.modifyItemNoteExternally(existingContactEditor.item, "Changed by another client")
        itemChangedExternallySpy.wait(5000)
        compare(itemFetchErrorSpy.count, 0)

        existingContactEditor.contact.note = "Kept my own edit"
        existingContactEditor.saveContactInAddressBook()

        saveSpy.wait(5000)
        compare(saveErrorSpy.count, 0)
        compare(existingContactEditor.saving, false)
        compare(existingContactEditor.contact.note, "Kept my own edit")
    }

}
