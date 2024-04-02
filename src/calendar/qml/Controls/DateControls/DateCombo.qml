// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kirigamiaddons.dateandtime

import "dateutils.js" as DateUtils

QQC2.ComboBox {
    id: root

    signal newDateChosen(int day, int month, int year)

    property int timeZoneOffset: 0
    property string display: dateTime.toLocaleDateString(Qt.locale(), Locale.NarrowFormat) // Can override for better C++ time strings
    property date dateTime: new Date()
    property date dateFromText: DateUtils.parseDateString(editText)
    property bool validDate: !isNaN(dateFromText.getTime())

    onDateTimeChanged: datePicker.value = dateTime;

    editable: true
    editText: activeFocus ? editText : display

    onActiveFocusChanged: {
        // Set date from text here because it otherwise updates after this handler
        // Also make sure to only update after we switch from this field's focus to something else
        if(!activeFocus) {
            dateFromText = DateUtils.parseDateString(editText);

            if (validDate) {
                datePicker.value = dateFromText;
                newDateChosen(dateFromText.getDate(), dateFromText.getMonth() + 1, dateFromText.getFullYear());
            }
        }
    }

    popup: DatePopup {
        id: datePicker

        width: Kirigami.Units.gridUnit * 18
        height: Kirigami.Units.gridUnit * 18
        y: parent.y + parent.height
        z: 1000
        padding: 0
        value: root.dateTime
        autoAccept: true

        onAccepted: {
            newDateChosen(value.getDate(), value.getMonth() + 1, value.getFullYear());
            datePicker.close();
        }
    }
}
