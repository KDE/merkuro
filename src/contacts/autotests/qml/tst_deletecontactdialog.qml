// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtTest

import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact

TestCase {
    id: testCase
    name: "DeleteContactDialogTest"
    when: windowShown
    width: 400
    height: 400

    readonly property var dialogComponent: Qt.createComponent(Qt.resolvedUrl("../../qml/private/DeleteContactDialog.qml"))

    Component {
        id: windowComponent
        Kirigami.ApplicationWindow {
            width: 400
            height: 400
        }
    }

    SignalSpy {
        id: itemFetchSpy
        target: contactTestItemProvider
        signalName: "itemChanged"
    }

    SignalSpy {
        id: existenceCheckSpy
        target: contactTestItemProvider
        signalName: "itemExistenceChecked"
    }

    function waitUntilItemDeleted(item: var): void {
        for (let i = 0; i < 20; i++) {
            existenceCheckSpy.clear()
            contactTestItemProvider.checkItemExists(item)
            existenceCheckSpy.wait(5000)
            if (existenceCheckSpy.signalArguments[0][0] === false) {
                return
            }
            wait(50)
        }
        fail("The item was not deleted in time")
    }

    function test_acceptingDeletesTheItem() {
        failOnWarning(/DeleteContactDialog\.qml/)

        if (itemFetchSpy.count === 0) {
            itemFetchSpy.wait(5000)
        }
        const item = contactTestItemProvider.item

        const window = createTemporaryObject(windowComponent, testCase)
        verify(window)

        const dialog = dialogComponent.createObject(window, {
            items: [item],
            names: ["QML Editor Test Contact"],
        })
        verify(dialog)

        dialog.accept()
        compare(dialog.standardButton(QQC2.Dialog.Ok).enabled, false)

        waitUntilItemDeleted(item)
    }
}
