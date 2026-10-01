// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar

Item {
    id: root
    width: 800
    height: 1000

    property Calendar.IncidenceWrapper wrapper

    Component {
        id: editorComponent
        Calendar.RecurrenceEditor {
            width: root.width
        }
    }

    SignalSpy {
        id: recurrenceSpy
        target: root.wrapper
        signalName: "recurrenceDataChanged"
    }

    TestCase {
        name: "RecurrenceEditorTest"
        when: windowShown

        function init(): void {
            root.wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        }

        function cleanup(): void {
            root.wrapper.destroy();
            root.wrapper = null;
        }

        function createEditor(kind: string): Calendar.RecurrenceEditor {
            editorTestHelper.setEditorFixture(root.wrapper, kind);
            recurrenceSpy.clear();
            const editor = createTemporaryObject(editorComponent, root, {
                incidenceWrapper: root.wrapper
            });
            verify(!!editor, "Component exists");
            return editor;
        }

        function control(editor: Calendar.RecurrenceEditor, name: string): var {
            const item = findChild(editor, name);
            verify(!!item, "Object exists");
            return item;
        }

        function test_loadingPreservesRule_data(): list<var> {
            return [
                {
                    tag: "weekly",
                    kind: "weekly"
                },
                {
                    tag: "monthly-position",
                    kind: "monthly-position"
                },
                {
                    tag: "monthly-date",
                    kind: "monthly-date"
                },
                {
                    tag: "yearly",
                    kind: "yearly"
                },
                {
                    tag: "hourly",
                    kind: "hourly"
                },
                {
                    tag: "count",
                    kind: "daily"
                },
                {
                    tag: "end-date",
                    kind: "end-date"
                }
            ];
        }

        function test_loadingPreservesRule(data: var): void {
            editorTestHelper.setEditorFixture(root.wrapper, data.kind);
            const before = editorTestHelper.draftContents(root.wrapper);
            recurrenceSpy.clear();
            const editor = createTemporaryObject(editorComponent, root, {
                incidenceWrapper: root.wrapper
            });
            verify(!!editor, "Component exists");
            tryCompare(control(editor, "recurFreqRuleSpinbox"), "value", root.wrapper.recurrenceData.frequency);
            compare(editorTestHelper.draftContents(root.wrapper), before);
            compare(recurrenceSpy.count, 0);
        }

        function test_modelUpdatesDoNotWriteBack(): void {
            const editor = createEditor("weekly");
            editorTestHelper.setEditorFixture(root.wrapper, "end-date");
            const expected = editorTestHelper.draftContents(root.wrapper);
            recurrenceSpy.clear();
            tryCompare(control(editor, "recurFreqRuleSpinbox"), "value", 2);
            tryCompare(control(editor, "recurEndDateCombo"), "visible", true);
            compare(editorTestHelper.draftContents(root.wrapper), expected);
            compare(recurrenceSpy.count, 0);
        }

        function test_customSelectionPreservesRule(): void {
            const editor = createEditor("monthly-position");
            const before = editorTestHelper.draftContents(root.wrapper);
            const repeat = control(editor, "repeatComboBox");
            repeat.activated(5);
            compare(editor.customMode, true);
            compare(editorTestHelper.draftContents(root.wrapper), before);
            compare(recurrenceSpy.count, 0);
        }

        function test_frequencyKeyboardEditUpdatesRule(): void {
            const editor = createEditor("weekly");
            const frequency = control(editor, "recurFreqRuleSpinbox");
            frequency.forceActiveFocus();
            tryCompare(frequency, "activeFocus", true);
            keyClick(Qt.Key_Up);
            tryVerify(() => root.wrapper.recurrenceData.frequency === 4);
            compare(root.wrapper.recurrenceData.duration, 9);
            compare(recurrenceSpy.count, 1);
            root.wrapper.setRecurrenceDataItem("frequency", 6);
            tryCompare(frequency, "value", 6);
            compare(recurrenceSpy.count, 2);
        }

        function test_weekdayClickUpdatesRule(): void {
            const editor = createEditor("weekly");
            const weekday = control(editor, "recurrenceWeekday2");
            compare(root.wrapper.recurrenceData.weekdays[2], false);
            mouseClick(weekday);
            tryVerify(() => root.wrapper.recurrenceData.weekdays[2]);
            compare(root.wrapper.recurrenceData.weekdays[0], true);
            compare(root.wrapper.recurrenceData.duration, 9);
            compare(recurrenceSpy.count, 1);
        }

        function test_monthlySelectionReplacesPattern(): void {
            const editor = createEditor("monthly-position");
            const monthlyDate = control(editor, "monthlyDateRadio");
            mouseClick(monthlyDate);
            tryVerify(() => root.wrapper.recurrenceData.type === 6);
            compare(root.wrapper.recurrenceData.monthDays.length, 1);
            compare(root.wrapper.recurrenceData.monthDays[0], 11);
            compare(root.wrapper.recurrenceData.monthPositions.length, 0);
            const monthlyPosition = control(editor, "monthlyPositionRadio");
            mouseClick(monthlyPosition);
            tryVerify(() => root.wrapper.recurrenceData.type === 5);
            compare(root.wrapper.recurrenceData.monthDays.length, 0);
            compare(root.wrapper.recurrenceData.monthPositions.length, 1);
            compare(root.wrapper.recurrenceData.monthPositions[0].pos, 2);
            compare(root.wrapper.recurrenceData.monthPositions[0].day, 4);
            compare(root.wrapper.recurrenceData.duration, 9);
            compare(recurrenceSpy.count, 2);
        }

        function test_occurrenceKeyboardEditUpdatesRule(): void {
            const editor = createEditor("weekly");
            const occurrences = control(editor, "recurOccurrenceEndSpinbox");
            occurrences.forceActiveFocus();
            tryCompare(occurrences, "fieldActiveFocus", true);
            keyClick(Qt.Key_Up);
            tryVerify(() => root.wrapper.recurrenceData.duration === 10);
            compare(recurrenceSpy.count, 1);
        }

        function test_selectingNeverClearsRule(): void {
            const editor = createEditor("weekly");
            control(editor, "repeatComboBox").activated(0);
            compare(root.wrapper.recurrenceData.type, 0);
            compare(recurrenceSpy.count, 1);
        }

        function test_endDateSelectionUpdatesRuleAndKeepsBinding(): void {
            const editor = createEditor("end-date");
            const date = control(editor, "recurEndDateCombo");
            date.newDateChosen(12, 8, 2026);
            compare(root.wrapper.recurrenceData.duration, 0);
            compare(root.wrapper.recurrenceData.endDateTime.day, 12);
            compare(root.wrapper.recurrenceData.endDateTime.month, 8);
            compare(root.wrapper.recurrenceData.frequency, 2);
            compare(recurrenceSpy.count, 1);
            root.wrapper.setRecurrenceDataItem("endDateTime", new Date(2026, 8, 15));
            tryVerify(() => date.dateTime.day === 15 && date.dateTime.month === 9);
            compare(recurrenceSpy.count, 2);
        }

        function test_endTypeSelectionUpdatesRule(): void {
            const editor = createEditor("weekly");
            const endType = control(editor, "endRecurType");
            endType.activated(0);
            compare(root.wrapper.recurrenceData.duration, -1);
            compare(recurrenceSpy.count, 1);
            endType.activated(2);
            compare(root.wrapper.recurrenceData.duration, 1);
            compare(recurrenceSpy.count, 2);
            endType.activated(1);
            compare(root.wrapper.recurrenceData.duration, 0);
            compare(root.wrapper.recurrenceData.endDateTime.isValid, true);
            compare(recurrenceSpy.count, 3);
        }
    }
}
