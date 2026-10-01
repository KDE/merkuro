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

    SignalSpy {
        id: recurrenceSpy
        target: root.wrapper
        signalName: "recurrenceDataChanged"
    }

    SignalSpy {
        id: categoriesSpy
        target: root.wrapper
        signalName: "categoriesChanged"
    }

    SignalSpy {
        id: attendeeSpy
        target: root.wrapper ? root.wrapper.attendeesModel : null
        signalName: "dataChanged"
    }

    SignalSpy {
        id: descriptionSpy
        target: root.wrapper
        signalName: "descriptionChanged"
    }

    SignalSpy {
        id: allDaySpy
        target: root.wrapper
        signalName: "allDayChanged"
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

        function test_openingPreservesFullDraft(): void {
            editorTestHelper.setEditorFixture(root.wrapper, "monthly-position");
            const expected = editorTestHelper.draftContents(root.wrapper);
            recurrenceSpy.clear();
            categoriesSpy.clear();
            attendeeSpy.clear();
            descriptionSpy.clear();
            const page = createPage(false);
            page.editMode = true;
            const attendeeName = findChild(page, "attendeeName0");
            verify(!!attendeeName, "Object exists");
            tryCompare(attendeeName, "text", "Fixture attendee");
            compare(editorTestHelper.draftContents(root.wrapper), expected);
            compare(recurrenceSpy.count, 0);
            compare(categoriesSpy.count, 0);
            compare(attendeeSpy.count, 0);
            compare(descriptionSpy.count, 0);
        }

        function test_openingUndatedTodoPreservesAllDay(): void {
            root.wrapper.setNewTodo();
            root.wrapper.allDay = true;
            allDaySpy.clear();
            const page = createPage(false);
            compare(root.wrapper.allDay, true);
            compare(allDaySpy.count, 0);
            verify(!!page, "Component exists");
        }

        function test_removingLastTodoDateClearsAllDay(): void {
            root.wrapper.setNewTodo();
            root.wrapper.setIncidenceTimeToNearestQuarterHour(true, false);
            root.wrapper.allDay = true;
            const page = createPage(false);
            const start = findChild(page, "incidenceStartCheckBox");
            verify(!!start, "Object exists");
            allDaySpy.clear();
            start.forceActiveFocus();
            tryCompare(start, "activeFocus", true);
            keyClick(Qt.Key_Space);
            tryVerify(() => !root.wrapper.incidenceStart.isValid);
            compare(root.wrapper.allDay, false);
            compare(allDaySpy.count, 1);
        }

        function test_reloadPreservesFullDraft(): void {
            editorTestHelper.setEditorFixture(root.wrapper, "weekly");
            editorTestHelper.prepareEditor(root.wrapper);
            const page = createPage(false);
            page.editMode = true;
            root.wrapper.description = "Unsaved notes";
            root.wrapper.categories = [];
            const expected = editorTestHelper.updateEditorFixture(root.wrapper, "monthly-position");
            const banner = findChild(page, "externalChangeMessage");
            verify(!!banner, "Object exists");
            banner.actions[0].trigger();
            const dialog = findChild(page, "reloadIncidenceDialog");
            verify(!!dialog, "Object exists");
            tryCompare(dialog, "opened", true);
            attendeeSpy.clear();
            dialog.accept();
            tryCompare(root.wrapper, "hasExternalChanges", false);
            compare(editorTestHelper.draftContents(root.wrapper), expected);
            const notes = findChild(page, "descriptionField");
            verify(!!notes, "Object exists");
            tryCompare(notes, "text", "Fixture notes");
            compare(attendeeSpy.count, 0);
            recurrenceSpy.clear();
            categoriesSpy.clear();
            descriptionSpy.clear();
            const selector = findChild(page, "categorySelector");
            verify(!!selector, "Object exists");
            tryVerify(() => selector.count > 0);
            selector.popup.open();
            tryCompare(selector.popup, "opened", true);
            compare(editorTestHelper.draftContents(root.wrapper), expected);
            compare(recurrenceSpy.count, 0);
            compare(categoriesSpy.count, 0);
            compare(descriptionSpy.count, 0);
            selector.popup.close();
        }

        function test_notesKeyboardEditsKeepBinding(): void {
            const page = createPage(false);
            const notes = findChild(page, "descriptionField");
            verify(!!notes, "Object exists");
            notes.forceActiveFocus();
            tryCompare(notes, "activeFocus", true);
            notes.selectAll();
            descriptionSpy.clear();
            keySequence("A");
            tryCompare(root.wrapper, "description", "a");
            compare(descriptionSpy.count, 1);
            root.wrapper.description = "Model notes";
            tryCompare(notes, "text", "Model notes");
            compare(descriptionSpy.count, 2);
        }

        function test_attendeeKeyboardEditsKeepBinding(): void {
            editorTestHelper.setEditorFixture(root.wrapper, "weekly");
            const page = createPage(false);
            const field = findChild(page, "attendeeName0");
            verify(!!field, "Object exists");
            field.forceActiveFocus();
            tryCompare(field, "activeFocus", true);
            field.selectAll();
            attendeeSpy.clear();
            keySequence("A");
            const attendees = root.wrapper.attendeesModel;
            tryVerify(() => attendees.data(attendees.index(0, 0), Calendar.AttendeesModel.NameRole) === "a");
            compare(attendeeSpy.count, 1);
            attendees.setData(attendees.index(0, 0), "Refreshed attendee", Calendar.AttendeesModel.NameRole);
            tryCompare(field, "text", "Refreshed attendee");
            compare(attendeeSpy.count, 2);
        }

        function test_categorySelectionKeepsBinding(): void {
            editorTestHelper.setEditorFixture(root.wrapper, "weekly");
            const page = createPage(false);
            const selector = findChild(page, "categorySelector");
            verify(!!selector, "Object exists");
            tryVerify(() => selector.count > 0);
            categoriesSpy.clear();
            selector.popup.open();
            tryCompare(selector.popup, "opened", true);
            const delegate = findChild(selector.popup.contentItem, "categoryDelegateEditor category");
            verify(!!delegate, "Object exists");
            compare(delegate.checked, true);
            compare(categoriesSpy.count, 0);
            mouseClick(delegate);
            tryVerify(() => root.wrapper.categories.length === 0);
            compare(categoriesSpy.count, 1);
            root.wrapper.categories = ["Editor category"];
            tryCompare(delegate, "checked", true);
            compare(categoriesSpy.count, 2);
            const checkbox = findChild(delegate, "categoryCheckboxEditor category");
            verify(!!checkbox, "Object exists");
            selector.popup.open();
            tryCompare(selector.popup, "opened", true);
            mouseClick(checkbox);
            tryVerify(() => root.wrapper.categories.length === 0);
            compare(categoriesSpy.count, 3);
            selector.popup.close();
        }

        function test_attendeeStatusAndRsvpOnlyWriteOnUserInput(): void {
            editorTestHelper.setEditorFixture(root.wrapper, "weekly");
            const page = createPage(false);
            page.editMode = true;
            const status = findChild(page, "attendeeStatus0");
            const rsvp = findChild(page, "attendeeRsvp0");
            verify(!!status, "Object exists");
            verify(!!rsvp, "Object exists");
            const attendees = root.wrapper.attendeesModel;
            const index = attendees.index(0, 0);
            attendeeSpy.clear();
            attendees.setData(index, false, Calendar.AttendeesModel.RSVPRole);
            tryCompare(rsvp, "checked", false);
            compare(attendeeSpy.count, 1);
            rsvp.forceActiveFocus();
            tryCompare(rsvp, "activeFocus", true);
            keyClick(Qt.Key_Space);
            tryVerify(() => attendees.data(index, Calendar.AttendeesModel.RSVPRole));
            compare(attendeeSpy.count, 2);
            status.forceActiveFocus();
            tryCompare(status, "activeFocus", true);
            keyClick(Qt.Key_Down);
            tryVerify(() => attendeeSpy.count === 3);
            compare(attendees.data(index, Calendar.AttendeesModel.StatusRole), status.currentValue);
        }

        function test_externalChangesRequireConfirmedReload(): void {
            editorTestHelper.prepareEditor(root.wrapper);
            root.wrapper.summary = "Unsaved draft";
            const page = createPage(false);
            page.editMode = true;
            editorTestHelper.updateEditor(root.wrapper, "External title");
            const banner = findChild(page, "externalChangeMessage");
            tryCompare(banner, "visible", true);
            compare(root.wrapper.summary, "Unsaved draft");
            compare(findChild(page, "saveButton").enabled, false);
            banner.actions[0].trigger();
            const dialog = findChild(page, "reloadIncidenceDialog");
            tryCompare(dialog, "opened", true);
            dialog.reject();
            compare(root.wrapper.summary, "Unsaved draft");
            compare(root.wrapper.hasExternalChanges, true);
            banner.actions[0].trigger();
            tryCompare(dialog, "opened", true);
            dialog.accept();
            tryCompare(root.wrapper, "summary", "External title");
            compare(root.wrapper.hasExternalChanges, false);
            tryCompare(findChild(page, "summaryField"), "text", "External title");
            tryCompare(findChild(page, "saveButton"), "enabled", true);
        }

        function test_deletionKeepsDraftAndDisablesSave(): void {
            editorTestHelper.prepareEditor(root.wrapper);
            root.wrapper.summary = "Draft before deletion";
            const page = createPage(false);
            page.editMode = true;
            editorTestHelper.removeEditor(root.wrapper);
            const banner = findChild(page, "externalChangeMessage");
            tryCompare(banner, "visible", true);
            compare(banner.actions[0].enabled, false);
            compare(banner.actions[0].visible, false);
            compare(findChild(page, "saveButton").enabled, false);
            compare(root.wrapper.summary, "Draft before deletion");
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
                if ((collection.rights & Akonadi.Collection.CanCreateItem) && collection.contentMimeTypes.indexOf("application/x-vnd.akonadi.calendar.event") !== -1) {
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
