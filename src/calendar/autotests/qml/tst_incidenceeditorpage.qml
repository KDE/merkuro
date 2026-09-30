// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

Item {
    id: root
    width: 800
    height: 600

    property Calendar.IncidenceWrapper wrapper

    Component {
        id: pageComponent
        Calendar.IncidenceEditorPage {
            width: root.width
            height: root.height
        }
    }

    SignalSpy {
        id: summarySpy
        target: root.wrapper
        signalName: "summaryChanged"
    }

    SignalSpy {
        id: completionSpy
        target: root.wrapper
        signalName: "todoPercentCompleteChanged"
    }

    SignalSpy {
        id: cancelSpy
        signalName: "cancel"
    }

    SignalSpy {
        id: itemSpy
        target: root.wrapper
        signalName: "incidenceItemChanged"
    }

    TestCase {
        name: "IncidenceEditorTest"
        when: windowShown

        function init(): void {
            root.wrapper = Calendar.CalendarManager.createIncidenceWrapper();
            root.wrapper.summary = "Editor test event";
            cancelSpy.clear();
            summarySpy.clear();
            completionSpy.clear();
        }

        function cleanup(): void {
            cancelSpy.target = null;
            root.wrapper.destroy();
            root.wrapper = null;
        }

        function createPage(todo: bool): Calendar.IncidenceEditorPage {
            if (todo) {
                root.wrapper.setNewTodo();
                root.wrapper.todoPercentComplete = 30;
                summarySpy.clear();
                completionSpy.clear();
            }
            const page = createTemporaryObject(pageComponent, root);
            verify(!!page, "Component exists");
            page.incidenceWrapper = root.wrapper;
            tryCompare(page, "validDates", true);
            return page;
        }

        function test_summaryModelUpdatesDoNotWriteBack(): void {
            const page = createPage(false);
            const field = findChild(page, "summaryField");
            verify(!!field, "Object exists");
            compare(field.text, "Editor test event");
            compare(summarySpy.count, 0);
            root.wrapper.summary = "Updated title";
            tryCompare(field, "text", "Updated title");
            compare(summarySpy.count, 1);
        }

        function test_summaryKeyboardEditsUpdateDraft(): void {
            const page = createPage(false);
            const field = findChild(page, "summaryField");
            verify(!!field, "Object exists");
            field.forceActiveFocus();
            tryCompare(field, "fieldActiveFocus", true);
            field.selectAll();
            keySequence("A");
            keySequence("1");
            keySequence("-");
            tryCompare(root.wrapper, "summary", "a1-");
            summarySpy.clear();
            root.wrapper.summary = "Refreshed title";
            tryCompare(field, "text", "Refreshed title");
            compare(summarySpy.count, 1);
        }

        function test_completionModelUpdatesDoNotWriteBack(): void {
            const page = createPage(true);
            const slider = findChild(page, "completionSlider");
            verify(!!slider, "Object exists");
            compare(slider.value, 30);
            compare(completionSpy.count, 0);
            root.wrapper.todoPercentComplete = 60;
            tryCompare(slider, "value", 60);
            compare(completionSpy.count, 1);
        }

        function test_completionKeyboardEditsUpdateDraft(): void {
            const page = createPage(true);
            const slider = findChild(page, "completionSlider");
            verify(!!slider, "Object exists");
            slider.forceActiveFocus();
            tryCompare(slider, "activeFocus", true);
            keyClick(Qt.Key_Right);
            tryCompare(root.wrapper, "todoPercentComplete", 40);
            compare(completionSpy.count, 1);
            completionSpy.clear();
            root.wrapper.todoPercentComplete = 70;
            tryCompare(slider, "value", 70);
            compare(completionSpy.count, 1);
        }

        function writableCalendarId(model: var, parentIndex: var): real {
            for (let row = 0; row < model.rowCount(parentIndex); ++row) {
                const index = model.index(row, 0, parentIndex);
                const collection = model.data(index, Akonadi.EntityTreeModel.CollectionRole);
                if ((collection.rights & Akonadi.Collection.CanCreateItem)
                    && collection.contentMimeTypes.indexOf("application/x-vnd.akonadi.calendar.event") !== -1) {
                    return collection.id;
                }
                const childId = writableCalendarId(model, index);
                if (childId > 0) {
                    return childId;
                }
            }
            return -1;
        }

        function test_failureKeepsDraftOpen(): void {
            const page = createPage(false);
            cancelSpy.target = page;
            tryCompare(page, "validDates", true);
            root.wrapper.collectionId = 999999;
            page.save();
            compare(cancelSpy.count, 0);
            compare(page.saving, false);
            compare(root.wrapper.summary, "Editor test event");
            const errorBanner = findChild(page, "saveErrorMessage");
            verify(errorBanner);
            tryCompare(errorBanner, "visible", true);
            verify(errorBanner.text.length > 0);
            const saveButton = findChild(page, "saveButton");
            verify(saveButton.enabled);
        }

        function test_closesOnlyAfterSuccessfulSave(): void {
            const page = createPage(false);
            cancelSpy.target = page;
            tryCompare(page, "validDates", true);
            const collections = Calendar.CalendarManager.collections;
            tryVerify(() => writableCalendarId(collections, collections.index(-1, -1)) > 0);
            root.wrapper.collectionId = writableCalendarId(collections, collections.index(-1, -1));
            itemSpy.clear();
            page.save();
            compare(page.saving, true);
            compare(cancelSpy.count, 0);
            const saveButton = findChild(page, "saveButton");
            compare(saveButton.enabled, false);
            page.save();
            tryCompare(cancelSpy, "count", 1);
            compare(page.saving, false);
            verify(itemSpy.count > 0);
            compare(Calendar.Config.lastUsedEventCollection, root.wrapper.collectionId);
            verify(!findChild(page, "saveErrorMessage").visible);
        }
    }
}
