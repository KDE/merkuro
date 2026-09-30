// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

TestCase {
    id: testCase
    name: "IncidenceEditorPageTest"
    when: windowShown
    visible: true
    width: 800
    height: 600

    property Calendar.IncidenceWrapper wrapper

    Component {
        id: pageComponent
        Calendar.IncidenceEditorPage {}
    }

    SignalSpy {
        id: cancelSpy
        signalName: "cancel"
    }

    SignalSpy {
        id: itemSpy
        target: testCase.wrapper
        signalName: "incidenceItemChanged"
    }

    function init(): void {
        wrapper = Calendar.CalendarManager.createIncidenceWrapper();
        wrapper.summary = "Editor test event";
        cancelSpy.clear();
    }

    function cleanup(): void {
        cancelSpy.target = null;
        wrapper.destroy();
        wrapper = null;
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
        const page = createTemporaryObject(pageComponent, testCase);
        verify(page);
        page.incidenceWrapper = wrapper;
        cancelSpy.target = page;
        tryCompare(page, "validDates", true);
        wrapper.collectionId = 999999;
        page.save();
        compare(cancelSpy.count, 0);
        compare(page.saving, false);
        compare(wrapper.summary, "Editor test event");
        const errorBanner = findChild(page, "saveErrorMessage");
        verify(errorBanner);
        tryCompare(errorBanner, "visible", true);
        verify(errorBanner.text.length > 0);
        const saveButton = findChild(page, "saveButton");
        verify(saveButton.enabled);
    }

    function test_closesOnlyAfterSuccessfulSave(): void {
        const page = createTemporaryObject(pageComponent, testCase);
        verify(page);
        page.incidenceWrapper = wrapper;
        cancelSpy.target = page;
        tryCompare(page, "validDates", true);
        const collections = Calendar.CalendarManager.collections;
        tryVerify(() => writableCalendarId(collections, collections.index(-1, -1)) > 0);
        wrapper.collectionId = writableCalendarId(collections, collections.index(-1, -1));
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
        compare(Calendar.Config.lastUsedEventCollection, wrapper.collectionId);
        verify(!findChild(page, "saveErrorMessage").visible);
    }
}
