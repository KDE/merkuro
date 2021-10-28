// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import "dateutils.js" as DateUtils

/* This combo box lets you edit an incidence's time while presenting you with the time in the incidence's set time zone.
 * Because of the limited ways that QML lets you access hour/minute data on a date object, and the limited ways it allows
 * you to convert a date to a string, this is significantly more complicated than one would expect.
 *
 * As a result, we need to create new date objects to present to the user that are in the local time zone but still have
 * the same hour and minute data as the date's own timezone.
 *
 * The time picker is not aware of these differences and is simply given the times that the user sees.
 */

QQC2.ComboBox {
    id: root

    signal newTimeChosen(date newTime)

    property int timeZoneOffset: 0
    property date dateTime
    property RegularExpressionValidator timeValidator: RegularExpressionValidator {
        regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
    }
    property RegularExpressionValidator inputValidator: RegularExpressionValidator {
        regularExpression: /[0-9]{0,2}[:][0-9]{0,2}/
    }
    property alias timePicker: popupTimePicker

    editable: true
    editText: activeFocus && !popupTimePicker.visible ? editText : DateUtils.adjustDateTimeToLocalTimeZone(dateTime, timeZoneOffset).toLocaleTimeString(Qt.locale(), "HH:mm")

    inputMethodHints: Qt.ImhTime
    validator: activeFocus ? inputValidator : timeValidator

    onEditTextChanged: {

        if (acceptableInput && activeFocus && !popupTimePicker.visible) { // Need to check for activeFocus or on load the text gets reset to 00:00
            const dateFromTime = Date.fromLocaleTimeString(Qt.locale(), editText, "HH:mm");
            if(!isNaN(dateFromTime.getTime())) {
                newTimeChosen(new Date(DateUtils.adjustDateTimeToLocalTimeZone(dateTime, timeZoneOffset).setHours(dateFromTime.getHours(), dateFromTime.getMinutes())));
            }
        }
    }

    popup: QQC2.Popup {
        id: timePopup
        width: parent.width
        height: parent.width * 1.5
        y: parent.y + parent.height
        z: 1000

        TimePicker {
            id: popupTimePicker

            Component.onCompleted: minuteMultiples = 5
            Connections {
                target: root

                function timeChangeHandler() {
                    if(!popupTimePicker.visible) {
                        const adjusted = DateUtils.adjustDateTimeToLocalTimeZone(root.dateTime, root.timeZoneOffset)
                        popupTimePicker.hours = adjusted.getHours();
                        popupTimePicker.minutes = adjusted.getMinutes();
                        console.log(dateTime, adjusted, root.timeZoneOffset, popupTimePicker.hours, popupTimePicker.minutes);
                    }
                }

                function onDateTimeChanged() {
                    timeChangeHandler();
                }

                function onTimeZoneOffsetChanged() {
                    timeChangeHandler();
                }
            }

            function valuesChangedHandler() {
                if(visible) {
                    const newDt = new Date(DateUtils.adjustDateTimeToLocalTimeZone(root.dateTime, root.timeZoneOffset).setHours(hours, minutes));
                    root.newTimeChosen(newDt);
                }
            }

            onHoursChanged: valuesChangedHandler()
            onMinutesChanged: valuesChangedHandler()
        }
    }
}
