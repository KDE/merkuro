// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.components as MerkuroComponents

QQC2.ComboBox {
    id: root

    signal newDateChosen(int day, int month, int year)

    property int timeZoneOffset: 0
    property string display: dateTime.toLocaleDateString(Locale.NarrowFormat) // Can override for better C++ time strings
    property MerkuroComponents.KDateTime dateTime: MerkuroComponents.KDateTimeFactory.now()
    property MerkuroComponents.KDateTime dateFromText: Calendar.Utils.parseDateString(editText)
    property bool validDate: dateFromText.isValid

    editable: true
    editText: activeFocus ? editText : display

    onPressedChanged: if (pressed) {
        Calendar.DatePopupSingleton.value = root.dateTime.dateTime;
        Calendar.DatePopupSingleton.popupParent = root;
        Calendar.DatePopupSingleton.y = y + height;
        connect.enabled = true;
    }

    onActiveFocusChanged: {
        // Set date from text here because it otherwise updates after this handler
        // Also make sure to only update after we switch from this field's focus to something else
        if(!activeFocus) {
            dateFromText = Calendar.Utils.parseDateString(editText);

            if (validDate) {
                newDateChosen(dateFromText.day, dateFromText.month, dateFromText.year);
            }
        }
    }

    popup: Calendar.DatePopupSingleton.popup

    Connections {
        id: connect

        target: Calendar.DatePopupSingleton

        enabled: false

        function onAccepted(): void {
            const value = MerkuroComponents.KDateTimeFactory.fromDateTime(Calendar.DatePopupSingleton.value);
            root.newDateChosen(value.day, value.month, value.year);
            Calendar.DatePopupSingleton.close();
        }

        function onClosed(): void {
            enabled = false;
        }
    }
}
