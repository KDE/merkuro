// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar

TestCase {
    id: testCase
    name: "IncidenceWrapperQmlTest"

    property Calendar.IncidenceWrapper wrapper

    Text {
        id: summaryBinding
        text: testCase.wrapper ? testCase.wrapper.summary : ""
    }

    Component {
        id: remindersComponent
        Calendar.RemindersModel {}
    }

    function init(): void {
        wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        wrapper.setNewEvent();
    }

    function cleanup(): void {
        wrapper.destroy();
        wrapper = null;
    }

    function test_summaryBinding(): void {
        wrapper.summary = "Team meeting";
        compare(summaryBinding.text, "Team meeting");
        wrapper.summary = "Planning meeting";
        compare(summaryBinding.text, "Planning meeting");
    }

    function test_newTodo(): void {
        wrapper.setNewTodo();
        compare(wrapper.incidenceType, Calendar.IncidenceWrapper.TypeTodo);
        wrapper.todoPercentComplete = 50;
        compare(wrapper.todoPercentComplete, 50);
        compare(wrapper.todoCompleted, false);
    }

    function test_remindersUsableFromQml(): void {
        const reminders = createTemporaryObject(remindersComponent, testCase, {
            incidence: wrapper.incidencePtr
        });
        verify(reminders);
        const initialCount = reminders.rowCount();
        reminders.addAlarm();
        compare(reminders.rowCount(), initialCount + 1);
        const index = reminders.index(initialCount, 0);
        verify(reminders.setData(index, -900, Calendar.RemindersModel.StartOffsetRole));
        compare(reminders.data(index, Calendar.RemindersModel.StartOffsetRole), -900);
        reminders.deleteAlarm(initialCount);
        compare(reminders.rowCount(), initialCount);
    }
}
