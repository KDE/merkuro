// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import org.kde.merkuro.calendar as Calendar

TestCase {
    id: root
    name: "CalendarIncidenceJob"

    property Calendar.CalendarIncidenceJob job
    property int results: 0
    property int resultError: 0
    property string resultErrorText
    property string resultErrorString

    Connections {
        target: root.job
        function onResult(): void {
            root.resultError = root.job.error;
            root.resultErrorText = root.job.errorText;
            root.resultErrorString = root.job.errorString;
            root.results++;
        }
    }

    function init(): void {
        results = 0;
        resultError = 0;
        resultErrorText = "";
        resultErrorString = "";
    }

    function test_invalidEditReturnsJob(): void {
        job = Calendar.CalendarManager.editIncidence(null);
        verify(job);
        compare(results, 0);
        tryCompare(root, "results", 1);
        verify(resultError !== 0);
        verify(resultErrorText.length > 0);
        compare(resultErrorString, resultErrorText);
        // Completed operations are automatically deleted by KJob.
        tryCompare(root, "job", null);
    }

    function test_invalidDateChangeReturnsJob(): void {
        job = Calendar.CalendarManager.updateIncidenceDates(null, 0, 0);
        verify(job);
        compare(results, 0);
        tryCompare(root, "results", 1);
        verify(resultError !== 0);
        verify(resultErrorText.length > 0);
        tryCompare(root, "job", null);
    }
}
