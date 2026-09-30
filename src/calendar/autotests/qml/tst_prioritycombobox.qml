// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar

TestCase {
    id: testCase
    name: "PriorityComboBoxTest"
    when: windowShown
    visible: true
    width: 400
    height: 400

    Component {
        id: comboComponent
        Calendar.PriorityComboBox {
            isTodo: true
        }
    }

    function test_priorityValues(): void {
        const combo = createTemporaryObject(comboComponent, testCase);
        verify(combo);
        compare(combo.count, 10);
        for (let priority = 0; priority <= 9; ++priority) {
            combo.currentIndex = priority;
            compare(combo.currentValue, priority);
            verify(combo.currentText.length > 0);
        }
    }

    function test_onlyVisibleForTodos(): void {
        const combo = createTemporaryObject(comboComponent, testCase);
        verify(combo);
        compare(combo.visible, true);
        combo.isTodo = false;
        compare(combo.visible, false);
        combo.isTodo = true;
        compare(combo.visible, true);
    }
}
