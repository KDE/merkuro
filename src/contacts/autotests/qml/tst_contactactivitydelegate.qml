// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtTest

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import "../../qml/private" as Private

TestCase {
    id: testCase
    name: "ContactActivityDelegateTest"
    visible: true
    when: windowShown

    Component {
        id: activityCardComponent

        Item {
            id: activityCard

            property int activityKind: ContactActivityModel.Messages

            width: 400
            height: 120

            FormCard.FormCard {
                anchors.fill: parent

                Repeater {
                    model: ListModel {
                        ListElement {
                            title: "Subject"
                            date: "Today"
                            person: "Ada Lovelace"
                            email: "ada@example.org"
                            unread: true
                        }
                    }

                    delegate: Private.ContactActivityDelegate {
                        objectName: "activityDelegate"
                        kind: activityCard.activityKind
                    }
                }
            }
        }
    }

    function test_modelRolesCreateDelegate(): void {
        const card = createTemporaryObject(activityCardComponent, testCase)
        verify(card)
        const delegate = findChild(card, "activityDelegate")
        verify(delegate)
        compare(delegate.title, "Subject")
        compare(delegate.person, "Ada Lovelace")
        verify(delegate.unread)
        verify(findChild(delegate, "unreadIndicator").visible)
        verify(delegate.background.visible)
    }

    function test_eventHasNoBackground(): void {
        const card = createTemporaryObject(activityCardComponent, testCase, { activityKind: ContactActivityModel.Events })
        verify(card)
        const delegate = findChild(card, "activityDelegate")
        verify(delegate)
        verify(!delegate.background.visible)
    }
}
