// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.components as MerkuroComponents

FormCard.FormCard {
    id: root

    required property Calendar.IncidenceWrapper incidenceWrapper
    property bool customMode: false
    enabled: !!root.incidenceWrapper
    readonly property bool isTodo: incidenceWrapper?.incidenceType === Calendar.IncidenceWrapper.TypeTodo

    Connections {
        target: root.incidenceWrapper
        function onIncidencePtrChanged(): void {
            root.customMode = false;
        }
    }

    FormCard.FormComboBoxDelegate {
        id: repeatComboBox
        objectName: "repeatComboBox"
        text: i18n("Repeat:")

        enabled: root.incidenceWrapper && (!root.isTodo || root.incidenceWrapper.incidenceStart.isValid || root.incidenceWrapper.incidenceEnd.isValid)
        textRole: "displayName"
        valueRole: "interval"
        currentIndex: {
            if (root.customMode) {
                return 5;
            }
            if (!root.incidenceWrapper) {
                return 0;
            }
            switch (root.incidenceWrapper.recurrenceData.type) {
            case 1: // Minutely
            case 2: // Hourly
                return 5;
            case 0:
                return root.incidenceWrapper?.recurrenceData.type;
            case 3: // Daily
                return root.incidenceWrapper?.recurrenceData.frequency === 1 ? root.incidenceWrapper?.recurrenceData.type - 2 : 5;
            case 4: // Weekly
                return root.incidenceWrapper?.recurrenceData.frequency === 1 ? (!root.incidenceWrapper?.recurrenceData.weekdays.includes(true) ? root.incidenceWrapper?.recurrenceData.type - 2 : 5) : 5;
            case 5: // Monthly on position (e.g. third Monday)
            case 8: // Yearly on day
            case 9: // Yearly on position
            case 10: // Other
                return 5;
            case 6: // Monthly on day (1st of month)
                return root.incidenceWrapper?.recurrenceData.frequency === 1 ? 3 : 5;
            case 7: // Yearly on month
                return root.incidenceWrapper?.recurrenceData.frequency === 1 ? 4 : 5;
            }
        }
        model: [
            {
                key: "never",
                displayName: i18n("Never"),
                interval: -1
            },
            {
                key: "daily",
                displayName: i18n("Daily"),
                interval: Calendar.IncidenceWrapper.Daily
            },
            {
                key: "weekly",
                displayName: i18n("Weekly"),
                interval: Calendar.IncidenceWrapper.Weekly
            },
            {
                key: "monthly",
                displayName: i18n("Monthly"),
                interval: Calendar.IncidenceWrapper.Monthly
            },
            {
                key: "yearly",
                displayName: i18n("Yearly"),
                interval: Calendar.IncidenceWrapper.Yearly
            },
            {
                key: "custom",
                displayName: i18n("Custom"),
                interval: -1
            }
        ]

        onActivated: function (index: int): void {
            root.customMode = index === 5;
            if (index === 0) {
                root.incidenceWrapper.clearRecurrences();
            } else if (index === 5) {
                if (root.incidenceWrapper?.recurrenceData.type === 0) {
                    root.incidenceWrapper.setRegularRecurrence(Calendar.IncidenceWrapper.Daily);
                }
            } else {
                root.incidenceWrapper.setRegularRecurrence(model[index].interval);
            }
        }
    }

    function setOccurrence(): void {
        root.incidenceWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);
    }

    FormCard.AbstractFormDelegate {
        visible: repeatComboBox.currentIndex === 5
        contentItem: RowLayout {
            QQC2.Label {
                text: i18n("Every:")
            }

            QQC2.SpinBox {
                id: recurFreqRuleSpinbox
                objectName: "recurFreqRuleSpinbox"

                Layout.fillWidth: true
                from: 1
                value: (root.incidenceWrapper?.recurrenceData.frequency ?? 1)
                onValueModified: root.incidenceWrapper.setRecurrenceDataItem("frequency", value)
            }
            QQC2.ComboBox {
                id: recurScaleRuleCombobox
                objectName: "recurScaleRuleCombobox"

                Layout.fillWidth: true
                visible: repeatComboBox.currentIndex === 5

                textRole: "displayName"
                valueRole: "interval"
                onActivated: root.setOccurrence()
                currentIndex: {
                    if (root.incidenceWrapper?.recurrenceData.type === undefined) {
                        return 0;
                    }

                    switch (root.incidenceWrapper?.recurrenceData.type) {
                    case 3: // Daily
                    case 4: // Weekly
                        return root.incidenceWrapper?.recurrenceData.type - 3;
                    case 5: // Monthly on position (e.g. third Monday)
                    case 6: // Monthly on day (1st of month)
                        return 2;
                    case 7: // Yearly on month
                    case 8: // Yearly on day
                    case 9: // Yearly on position
                        return 3;
                    default:
                        return 0;
                    }
                }

                model: [
                    {
                        key: "day",
                        displayName: i18np("day", "days", recurFreqRuleSpinbox.value),
                        interval: Calendar.IncidenceWrapper.Daily
                    },
                    {
                        key: "week",
                        displayName: i18np("week", "weeks", recurFreqRuleSpinbox.value),
                        interval: Calendar.IncidenceWrapper.Weekly
                    },
                    {
                        key: "month",
                        displayName: i18np("month", "months", recurFreqRuleSpinbox.value),
                        interval: Calendar.IncidenceWrapper.Monthly
                    },
                    {
                        key: "year",
                        displayName: i18np("year", "years", recurFreqRuleSpinbox.value),
                        interval: Calendar.IncidenceWrapper.Yearly
                    },
                ]
            }
        }
    }

    FormCard.AbstractFormDelegate {
        visible: recurScaleRuleCombobox.currentValue === Calendar.IncidenceWrapper.Weekly && repeatComboBox.currentValue === -1
        contentItem: GridLayout {
            id: recurWeekdayRuleLayout
            columns: 7
            Repeater {
                model: 7
                delegate: QQC2.Label {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName(Qt.locale().firstDayOfWeek + index, Locale.ShortFormat)
                }
            }

            Repeater {
                id: weekdayCheckboxRepeater

                model: 7
                delegate: QQC2.CheckBox {
                    required property int index
                    // We make sure we get dayNumber per the day of the week number used by C++ Qt
                    property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ? Qt.locale().firstDayOfWeek + index - 1 - 7 : Qt.locale().firstDayOfWeek + index - 1

                    objectName: "recurrenceWeekday" + dayNumber
                    checked: root.incidenceWrapper?.recurrenceData?.weekdays[dayNumber] ?? false
                    onClicked: {
                        let newWeekdays = [...root.incidenceWrapper?.recurrenceData.weekdays];
                        newWeekdays[dayNumber] = !root.incidenceWrapper?.recurrenceData.weekdays[dayNumber];
                        root.incidenceWrapper.setRecurrenceDataItem("weekdays", newWeekdays);
                    }

                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    QQC2.ButtonGroup {
        id: monthlyRecurrenceGroup
    }

    FormCard.AbstractFormDelegate {
        visible: recurScaleRuleCombobox.currentValue === Calendar.IncidenceWrapper.Monthly && repeatComboBox.currentIndex === 5
        contentItem: ColumnLayout {
            id: monthlyRecurRadioColumn

            readonly property MerkuroComponents.KDateTime incidenceStartDateFromText: root.incidenceWrapper?.incidenceStart ?? MerkuroComponents.KDateTimeFactory.invalid()

            QQC2.Label {
                text: i18n("On:")
            }

            Layout.fillWidth: true

            QQC2.RadioButton {
                objectName: "monthlyDateRadio"
                QQC2.ButtonGroup.group: monthlyRecurrenceGroup
                property int dateOfMonth: monthlyRecurRadioColumn.incidenceStartDateFromText.day

                text: i18nc("%1 is the day number of month", "The %1 of each month", Calendar.LabelUtils.numberToString(dateOfMonth))

                checked: root.incidenceWrapper?.recurrenceData.type === 6 // Monthly on day (1st of month)
                onClicked: root.incidenceWrapper.setMonthlyDateRecurrence(dateOfMonth)
            }

            QQC2.RadioButton {
                objectName: "monthlyPositionRadio"
                QQC2.ButtonGroup.group: monthlyRecurrenceGroup
                property int dayOfWeek: monthlyRecurRadioColumn.incidenceStartDateFromText.dayOfWeek - 1
                property int weekOfMonth: Math.ceil(monthlyRecurRadioColumn.incidenceStartDateFromText.day / 7)
                property string dayOfWeekString: Qt.locale().dayName(monthlyRecurRadioColumn.incidenceStartDateFromText.dayOfWeek)

                text: i18nc("the weekOfMonth dayOfWeekString of each month", "The %1 %2 of each month", Calendar.LabelUtils.numberToString(weekOfMonth), dayOfWeekString)
                checked: root.incidenceWrapper?.recurrenceData.type === 5 // Monthly on position
                onClicked: root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
            }
        }
    }

    FormCard.FormComboBoxDelegate {
        id: endRecurType
        objectName: "endRecurType"

        visible: repeatComboBox.currentIndex !== 0
        text: i18n("Ends:")
        // ?? Layout.fillWidth: currentIndex !== 1 //The end date combo box should fill the layout
        // Recurrence duration returns -1 for never ending and 0 when the recurrence
        // end date is set. Any number larger is the set number of recurrences
        onActivated: function (index: int): void {
            if (index === 0) {
                root.incidenceWrapper.setRecurrenceDataItem("duration", -1);
            } else if (index === 1) {
                root.incidenceWrapper.setRecurrenceDataItem("endDateTime", root.incidenceWrapper?.recurrenceData.endDateTime.isValid ? root.incidenceWrapper?.recurrenceData.endDateTime : root.incidenceWrapper.incidenceEnd);
            } else {
                root.incidenceWrapper.setRecurrenceOccurrences(Math.max(1, root.incidenceWrapper?.recurrenceData.duration ?? 1));
            }
        }
        textRole: "displayName"
        valueRole: "duration"
        model: [
            {
                displayName: i18n("Never"),
                duration: -1
            },
            {
                displayName: i18n("On"),
                duration: 0
            },
            {
                displayName: i18n("After"),
                duration: 1
            }
        ]

        currentIndex: !root.incidenceWrapper ? 0 : root.incidenceWrapper.recurrenceData.duration <= 0 ? root.incidenceWrapper.recurrenceData.duration + 1 : 2
    }

    FormCard.AbstractFormDelegate {
        visible: endRecurType.visible && endRecurType.currentIndex === 1
        contentItem: Calendar.DateCombo {
            id: recurEndDateCombo
            objectName: "recurEndDateCombo"
            dateTime: root.incidenceWrapper?.recurrenceData.endDateTime ?? MerkuroComponents.KDateTimeFactory.invalid()
            onNewDateChosen: function (day: int, month: int, year: int): void {
                root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date(year, month - 1, day));
            }
        }
    }

    FormCard.FormSpinBoxDelegate {
        id: recurOccurrenceEndSpinbox
        objectName: "recurOccurrenceEndSpinbox"
        label: i18nc("@label:spinbox", "Ends after:")
        textFromValue: function (value: int): string {
            return i18np("%1 occurrence", "%1 occurrences", value);
        }
        visible: endRecurType.currentIndex === 2
        from: 1
        value: Math.max(1, root.incidenceWrapper?.recurrenceData.duration ?? 1)
        onValueModified: root.incidenceWrapper.setRecurrenceOccurrences(value)
    }

    FormCard.FormTextDelegate {
        text: i18n("Exceptions:")
        visible: repeatComboBox.currentIndex !== 0
        trailing: QQC2.Button {
            text: i18nc("@action:button", "Add")
            icon.name: "list-add"
            onClicked: {
                Calendar.DatePopupSingleton.value = root.incidenceWrapper.incidenceEnd.dateTime;
                Calendar.DatePopupSingleton.popupParent = root;
                Calendar.DatePopupSingleton.y = y + height;
                Calendar.DatePopupSingleton.open();
                connect.enabled = true;
            }
            Connections {
                id: connect

                target: Calendar.DatePopupSingleton
                enabled: false

                function onAccepted(): void {
                    root.incidenceWrapper?.recurrenceExceptionsModel.addExceptionDateTime(MerkuroComponents.KDateTimeFactory.fromDateTime(Calendar.DatePopupSingleton.value));
                    Calendar.DatePopupSingleton.close();
                }

                function onClosed(): void {
                    enabled = false;
                }
            }
        }
    }

    Repeater {
        model: root.incidenceWrapper?.recurrenceExceptionsModel

        delegate: FormCard.FormTextDelegate {
            id: exceptionDelegate

            required property MerkuroComponents.KDateTime date

            leftPadding: Kirigami.Units.largeSpacing * 4

            text: date.toLocaleDateString(Locale.NarrowFormat)
            trailing: QQC2.Button {
                icon.name: "edit-delete-remove"
                onClicked: root.incidenceWrapper?.recurrenceExceptionsModel.deleteExceptionDateTime(date)
            }
        }
    }
}
