// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import QtLocation
import Qt.labs.qmlmodels
import org.kde.kitemmodels
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.dateandtime
import org.kde.merkuro.contact
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

Kirigami.ScrollablePage {
    id: root

    signal cancel

    // Setting the incidenceWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property var incidenceWrapper

    property bool editMode: false
    property bool validDates: {
        if(incidenceWrapper && incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
            return editorLoader.active && editorLoader.item.validEndDate
        } else if (incidenceWrapper) {
            return editorLoader.active && editorLoader.item.validFormDates &&
                (incidenceWrapper.allDay || incidenceWrapper.incidenceStart <= incidenceWrapper.incidenceEnd)
        } else {
            return false;
        }
    }

    title: if (incidenceWrapper) {
        editMode ? i18nc("%1 is incidence type", "Edit %1", incidenceWrapper.incidenceTypeStr) :
            i18nc("%1 is incidence type", "Add %1", incidenceWrapper.incidenceTypeStr);
    } else {
        "";
    }

    header: Components.Banner {
        id: invalidDateMessage

        width: parent.width
        visible: !root.validDates
        type: Kirigami.MessageType.Error
        // Specify what the problem is to aid user
        text: if (root.incidenceWrapper && root.incidenceWrapper.incidenceStart < root.incidenceWrapper.incidenceEnd) {
            return i18n("Invalid dates provided.");
        } else {
            return i18n("End date cannot be before start date.");
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: root.editMode ? "document-save" : "list-add"
            text: root.editMode ? i18n("Save") : i18n("Add")
            enabled: root.validDates && root.incidenceWrapper.summary && incidenceWrapper.collectionId
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: root.cancel()
        onAccepted: submitAction.trigger()
    }

    QQC2.Action {
        id: submitAction
        enabled: root.validDates && root.incidenceWrapper.summary && incidenceWrapper.collectionId
        shortcut: "Return"
        onTriggered: {
            if (root.editMode) {
                Calendar.CalendarManager.editIncidence(root.incidenceWrapper);
            } else if (root.validDates) {
                if(root.incidenceWrapper.collectionId < 0) {
                    root.incidenceWrapper.collectionId = editorLoader.item.calendarCombo.currentValue;
                }
                if (root.incidenceWrapper.collectionId < 0) {
                    root.incidenceWrapper.collectionId = editorLoader.item.calendarCombo.defaultCollectionId;
                }

                if(root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
                    Calendar.Config.lastUsedTodoCollection = root.incidenceWrapper.collectionId;
                } else {
                    Calendar.Config.lastUsedEventCollection = root.incidenceWrapper.collectionId;
                }
                Calendar.Config.save();

                Calendar.CalendarManager.addIncidence(incidenceWrapper);
            }
            cancel(); // Easy way to close the editor
        }
    }

    Component {
        id: contactsPage

        ContactChooserPage {
            id: contactChooserPage

            Connections {
                target: root.incidenceWrapper.attendeesModel

                function onAttendeeDeleted(itemId: int): void {
                    contactChooserPage.removeAttendeeByItemId(itemId);
                }
            }

            attendeeAkonadiIds: root.incidenceWrapper.attendeesModel.attendeesAkonadiIds

            onAddAttendee: (itemId, email) => {
                root.incidenceWrapper.attendeesModel.addAttendee(itemId, email);
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
            onRemoveAttendee: itemId => {
                root.incidenceWrapper.attendeesModel.deleteAttendeeFromAkonadiId(itemId)
                root.flickable.contentY = editorLoader.item.attendeesColumnY;
            }
        }
    }

    Loader {
        id: editorLoader
        Layout.fillWidth: true
        Layout.fillHeight: true

        active: root.incidenceWrapper !== undefined
        sourceComponent: ColumnLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool validStartDate: incidenceForm.isTodo ?
                incidenceStartDateCombo.validDate || !incidenceStartCheckBox.checked :
                incidenceStartDateCombo.validDate
            property bool validEndDate: incidenceForm.isTodo ?
                incidenceEndDateCombo.validDate || !incidenceEndCheckBox.checked :
                incidenceEndDateCombo.validDate
            property bool validFormDates: validStartDate && (validEndDate || root.incidenceWrapper.allDay)

            property alias attendeesColumnY: attendeesColumn.y

            readonly property alias calendarCombo: calendarCombo

            Kirigami.FormLayout {
                id: incidenceForm

                property date todayDate: new Date()
                property bool isTodo: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo
                property bool isJournal: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeJournal

                Akonadi.CollectionComboBox {
                    id: calendarCombo

                    Kirigami.FormData.label: i18n("Calendar:")
                    Layout.fillWidth: true

                    defaultCollectionId: {
                        if (root.incidenceWrapper.collectionId === -1) {

                            if ((incidenceForm.isTodo && Calendar.Config.lastUsedTodoCollection === -1) ||
                                (!incidenceForm.isTodo && Calendar.Config.lastUsedEventCollection === -1)) {

                                return selectedCollectionId;
                            }
                            return incidenceForm.isTodo ? Calendar.Config.lastUsedTodoCollection : Calendar.Config.lastUsedEventCollection;
                        }
                        return root.incidenceWrapper.collectionId;
                    }

                    mimeTypeFilter: if (root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeEvent) {
                        return [Akonadi.MimeTypes.calendar]
                    } else if (root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
                        return [Akonadi.MimeTypes.todo]
                    }
                    accessRightsFilter: Akonadi.Collection.CanCreateItem
                    onUserSelectedCollection: collection => root.incidenceWrapper.setCollection(collection)
                }

                QQC2.TextField {
                    id: summaryField

                    Kirigami.FormData.label: i18n("Summary:")
                    placeholderText: switch (root.incidenceWrapper.incidenceType) {
                    case Calendar.IncidenceWrapper.TypeTodo:
                        return i18n("Add a title for your task")
                    case Calendar.IncidenceWrapper.TypeEvent:
                        return i18n("Add a title for your event")
                    case Calendar.IncidenceWrapper.TypeJournal:
                        return i18n("Add a title for your journal entry")
                    }
                    text: root.incidenceWrapper.summary
                    onTextChanged: root.incidenceWrapper.summary = text
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Completion:")
                    Layout.fillWidth: true
                    visible: incidenceForm.isTodo && root.editMode

                    QQC2.Slider {
                        Layout.fillWidth: true
                        orientation: Qt.Horizontal
                        from: 0
                        to: 100.0
                        stepSize: 10.0
                        value: root.incidenceWrapper.todoPercentComplete
                        onValueChanged: root.incidenceWrapper.todoPercentComplete = value
                    }
                    QQC2.Label {
                        text: String(root.incidenceWrapper.todoPercentComplete) + "\%"
                    }
                }

                Calendar.PriorityComboBox {
                    currentIndex: root.incidenceWrapper.priority
                    onCurrentValueChanged: root.incidenceWrapper.priority = currentValue
                    isTodo: incidenceForm.isTodo

                    Layout.fillWidth: true
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    visible: incidenceForm.isTodo
                }

                QQC2.CheckBox {
                    id: allDayCheckBox

                    text: i18n("All day")
                    enabled: !incidenceForm.isTodo || !isNaN(root.incidenceWrapper.incidenceStart.getTime()) || !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                    onEnabledChanged: if (!enabled) root.incidenceWrapper.allDay = false
                    checked: root.incidenceWrapper.allDay
                    onClicked: {
                        if (!checked) {
                            root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour();
                        }
                        root.incidenceWrapper.allDay = checked;
                    }
                }

                Connections {
                    target: root.incidenceWrapper
                    function onIncidenceStartChanged() {
                        incidenceStartDateCombo.dateTime = root.incidenceWrapper.incidenceStart;
                        incidenceStartTimeCombo.dateTime = root.incidenceWrapper.incidenceStart;
                        incidenceStartDateCombo.display = root.incidenceWrapper.incidenceStartDateDisplay;
                        incidenceStartTimeCombo.display = root.incidenceWrapper.incidenceStartTimeDisplay;
                    }

                    function onIncidenceEndChanged() {
                        incidenceEndDateCombo.dateTime = root.incidenceWrapper.incidenceEnd;
                        incidenceEndTimeCombo.dateTime = root.incidenceWrapper.incidenceEnd;
                        incidenceEndDateCombo.display = root.incidenceWrapper.incidenceEndDateDisplay;
                        incidenceEndTimeCombo.display = root.incidenceWrapper.incidenceEndTimeDisplay;
                    }
                }

                RowLayout {
                    id: incidenceStartLayout

                    Kirigami.FormData.label: i18n("Start:")
                    Layout.fillWidth: true
                    visible: !incidenceForm.isTodo || (incidenceForm.isTodo && !isNaN(root.incidenceWrapper.incidenceStart.getTime()))

                    QQC2.CheckBox {
                        id: incidenceStartCheckBox

                        property var oldDate

                        checked: !isNaN(root.incidenceWrapper.incidenceStart.getTime())
                        onClicked: {
                            if (!checked && incidenceForm.isTodo) {
                                oldDate = root.incidenceWrapper.incidenceStart
                                root.incidenceWrapper.incidenceStart = new Date(undefined)
                            } else if(incidenceForm.isTodo && oldDate) {
                                root.incidenceWrapper.incidenceStart = oldDate
                            } else if(incidenceForm.isTodo) {
                                root.incidenceWrapper.incidenceEnd = new Date()
                            }
                        }
                        visible: incidenceForm.isTodo
                    }


                    Calendar.DateCombo {
                        id: incidenceStartDateCombo

                        Layout.fillWidth: true
                        display: root.incidenceWrapper.incidenceStartDateDisplay
                        dateTime: root.incidenceWrapper.incidenceStart
                        onNewDateChosen: (day, month, year) => {
                            root.incidenceWrapper.setIncidenceStartDate(day, month, year)
                        }
                    }
                    Calendar.TimeCombo {
                        id: incidenceStartTimeCombo

                        Layout.fillWidth: true
                        timeZoneOffset: root.incidenceWrapper.startTimeZoneUTCOffsetMins
                        display: root.incidenceWrapper.incidenceEndTimeDisplay
                        dateTime: root.incidenceWrapper.incidenceStart
                        onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceStartTime(hours, minutes)
                        enabled: !allDayCheckBox.checked && (!incidenceForm.isTodo || incidenceStartCheckBox.checked)
                        visible: !allDayCheckBox.checked
                    }
                }
                RowLayout {
                    id: incidenceEndLayout

                    Kirigami.FormData.label: incidenceForm.isTodo ? i18n("Due:") : i18n("End:")
                    Layout.fillWidth: true
                    visible: !incidenceForm.isJournal || incidenceForm.isTodo

                    QQC2.CheckBox {
                        id: incidenceEndCheckBox

                        property var oldDate

                        checked: !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                        onClicked: { // If we use onCheckedChanged this will change the date during init
                            if(!checked && incidenceForm.isTodo) {
                                oldDate = root.incidenceWrapper.incidenceEnd
                                root.incidenceWrapper.incidenceEnd = new Date(undefined)
                            } else if(incidenceForm.isTodo && oldDate) {
                                root.incidenceWrapper.incidenceEnd = oldDate
                            } else if(incidenceForm.isTodo) {
                                root.incidenceWrapper.incidenceEnd = root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour(false, true);
                            }
                        }
                        visible: incidenceForm.isTodo
                    }

                    Calendar.DateCombo {
                        id: incidenceEndDateCombo

                        Layout.fillWidth: true
                        display: root.incidenceWrapper.incidenceEndDateDisplay
                        dateTime: root.incidenceWrapper.incidenceEnd
                        onNewDateChosen: (day, month, year) => {
                            root.incidenceWrapper.setIncidenceEndDate(day, month, year)
                        }
                        enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                    }
                    Calendar.TimeCombo {
                        id: incidenceEndTimeCombo

                        Layout.fillWidth: true
                        timeZoneOffset: root.incidenceWrapper.endTimeZoneUTCOffsetMins
                        display: root.incidenceWrapper.incidenceEndTimeDisplay
                        dateTime: root.incidenceWrapper.incidenceEnd
                        onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceEndTime(hours, minutes)
                        enabled: (!incidenceForm.isTodo && !allDayCheckBox.checked) || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                        visible: !allDayCheckBox.checked
                    }
                }

                QQC2.ComboBox {
                    id: timeZoneComboBox
                    Kirigami.FormData.label: i18n("Timezone:")
                    Layout.fillWidth: true

                    model: Calendar.TimeZoneListModel {
                        id: timeZonesModel
                    }

                    textRole: "displayName"
                    valueRole: "id"
                    currentIndex: model ? timeZonesModel.getTimeZoneRow(root.incidenceWrapper.timeZone) : -1
                    delegate: Delegates.RoundedItemDelegate {
                        required property int index
                        required property string displayName
                        required property string id

                        text: displayName
                        onClicked: root.incidenceWrapper.timeZone = id
                    }
                    enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                }

                QQC2.ComboBox {
                    id: repeatComboBox
                    Kirigami.FormData.label: i18n("Repeat:")
                    Layout.fillWidth: true

                    enabled: !incidenceForm.isTodo || !isNaN(root.incidenceWrapper.incidenceStart.getTime()) || !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                    textRole: "displayName"
                    valueRole: "interval"
                    onCurrentIndexChanged: if(currentIndex === 0) { root.incidenceWrapper.clearRecurrences() }
                    currentIndex: {
                        switch(root.incidenceWrapper.recurrenceData.type) {
                            case 0:
                                return root.incidenceWrapper.recurrenceData.type;
                            case 3: // Daily
                                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                                    root.incidenceWrapper.recurrenceData.type - 2 : 5
                            case 4: // Weekly
                                return root.incidenceWrapper.recurrenceData.frequency === 1 ?
                                    (root.incidenceWrapper.recurrenceData.weekdays.filter(x => x === true).length === 0 ?
                                    root.incidenceWrapper.recurrenceData.type - 2 : 5) : 5
                            case 5: // Monthly on position (e.g. third Monday)
                            case 8: // Yearly on day
                            case 9: // Yearly on position
                            case 10: // Other
                                return 5;
                            case 6: // Monthly on day (1st of month)
                                return 3;
                            case 7: // Yearly on month
                                return 4;
                        }
                    }
                    model: [
                        {key: "never", displayName: i18n("Never"), interval: -1},
                        {key: "daily", displayName: i18n("Daily"), interval: Calendar.IncidenceWrapper.Daily},
                        {key: "weekly", displayName: i18n("Weekly"), interval: Calendar.IncidenceWrapper.Weekly},
                        {key: "monthly", displayName: i18n("Monthly"), interval: Calendar.IncidenceWrapper.Monthly},
                        {key: "yearly", displayName: i18n("Yearly"), interval: Calendar.IncidenceWrapper.Yearly},
                        {key: "custom", displayName: i18n("Custom"), interval: -1}
                    ]
                    delegate: Delegates.RoundedItemDelegate {
                        required property int index
                        required property string displayName
                        required property int interval

                        text: displayName
                        onClicked: if (interval >= 0) {
                            root.incidenceWrapper.setRegularRecurrence(interval)
                        } else {
                            root.incidenceWrapper.clearRecurrences();
                        }
                    }
                    popup.z: 1000
                }

                Kirigami.FormLayout {
                    id: customRecurrenceLayout

                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    visible: repeatComboBox.currentIndex > 0 // Not "Never" index

                    function setOccurrence() {
                        root.incidenceWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);

                        if(recurScaleRuleCombobox.currentValue === Calendar.IncidenceWrapper.Weekly) {
                            weekdayCheckboxRepeater.setWeekdaysRepeat();
                        }
                    }

                    // Custom controls
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.FormData.label: i18n("Every:")
                        visible: repeatComboBox.currentIndex === 5

                        QQC2.SpinBox {
                            id: recurFreqRuleSpinbox

                            Layout.fillWidth: true
                            from: 1
                            value: root.incidenceWrapper.recurrenceData.frequency
                            onValueChanged: if(visible) { root.incidenceWrapper.setRecurrenceDataItem("frequency", value) }
                        }
                        QQC2.ComboBox {
                            id: recurScaleRuleCombobox

                            Layout.fillWidth: true
                            visible: repeatComboBox.currentIndex === 5
                            // Make sure it defaults to something
                            onVisibleChanged: if(visible && currentIndex < 0) { currentIndex = 0; customRecurrenceLayout.setOccurrence(); }

                            textRole: "displayName"
                            valueRole: "interval"
                            onCurrentValueChanged: if(visible) {
                                customRecurrenceLayout.setOccurrence();
                                repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                            }
                            currentIndex: {
                                if(root.incidenceWrapper.recurrenceData.type === undefined) {
                                    return -1;
                                }

                                switch(root.incidenceWrapper.recurrenceData.type) {
                                    case 3: // Daily
                                    case 4: // Weekly
                                        return root.incidenceWrapper.recurrenceData.type - 3
                                    case 5: // Monthly on position (e.g. third Monday)
                                    case 6: // Monthly on day (1st of month)
                                        return 2;
                                    case 7: // Yearly on month
                                    case 8: // Yearly on day
                                    case 9: // Yearly on position
                                        return 3;
                                    default:
                                        return -1;
                                }
                            }

                            model: [
                                {key: "day", displayName: i18np("day", "days", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Daily},
                                {key: "week", displayName: i18np("week", "weeks", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Weekly},
                                {key: "month", displayName: i18np("month", "months", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Monthly},
                                {key: "year", displayName: i18np("year", "years", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Yearly},
                            ]
                            delegate: Delegates.RoundedItemDelegate {
                                required property int index
                                required property string displayName

                                onClicked: {
                                    customRecurrenceLayout.setOccurrence();
                                    repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                                }
                            }

                            popup.z: 1000
                        }
                    }

                    // Custom controls specific to weekly
                    GridLayout {
                        id: recurWeekdayRuleLayout
                        Layout.fillWidth: true

                        columns: 7
                        visible: recurScaleRuleCombobox.currentIndex === 1 && repeatComboBox.currentIndex === 5 // "week"/"weeks" index

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

                            property var checkboxes: []
                            function setWeekdaysRepeat() {
                                let selectedDays = new Array(7)
                                for(let checkbox of checkboxes) {
                                    // C++ func takes 7 bit array
                                    selectedDays[checkbox.dayNumber] = checkbox.checked
                                }
                                root.incidenceWrapper.setRecurrenceDataItem("weekdays", selectedDays);
                            }

                            model: 7
                            delegate: QQC2.CheckBox {
                                required property int index
                                // We make sure we get dayNumber per the day of the week number used by C++ Qt
                                property int dayNumber: Qt.locale().firstDayOfWeek + index > 7 ?
                                                        Qt.locale().firstDayOfWeek + index - 1 - 7 :
                                                        Qt.locale().firstDayOfWeek + index - 1

                                checked: root.incidenceWrapper.recurrenceData?.weekdays[dayNumber] ?? false
                                onClicked: {
                                    let newWeekdays = [...root.incidenceWrapper.recurrenceData.weekdays];
                                    newWeekdays[dayNumber] = !root.incidenceWrapper.recurrenceData.weekdays[dayNumber];
                                    root.incidenceWrapper.setRecurrenceDataItem("weekdays", newWeekdays);
                                }

                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Controls specific to monthly recurrence
                    QQC2.ButtonGroup {
                        buttons: monthlyRecurRadioColumn.children
                    }

                    ColumnLayout {
                        id: monthlyRecurRadioColumn

                        Kirigami.FormData.label: i18n("On:")

                        Layout.fillWidth: true
                        visible: recurScaleRuleCombobox.currentIndex === 2 && repeatComboBox.currentIndex === 5 // "month/months" index

                        QQC2.RadioButton {
                            property int dateOfMonth: incidenceStartDateCombo.dateFromText.getDate()

                            text: i18nc("%1 is the day number of month", "The %1 of each month", Calendar.LabelUtils.numberToString(dateOfMonth))

                            checked: root.incidenceWrapper.recurrenceData.type === 6 // Monthly on day (1st of month)
                            onClicked: customRecurrenceLayout.setOccurrence()
                        }
                        QQC2.RadioButton {
                            property int dayOfWeek: incidenceStartDateCombo.dateFromText.getDay() > 0 ?
                                                    incidenceStartDateCombo.dateFromText.getDay() - 1 :
                                                    7 // C++ Qt day of week index goes Mon-Sun, 0-7
                            property int weekOfMonth: Math.ceil((incidenceStartDateCombo.dateFromText.getDate() + 6 - incidenceStartDateCombo.dateFromText.getDay())/7);
                            property string dayOfWeekString: Qt.locale().dayName(incidenceStartDateCombo.dateFromText.getDay())

                            text: i18nc("the weekOfMonth dayOfWeekString of each month", "The %1 %2 of each month", Calendar.LabelUtils.numberToString(weekOfMonth), dayOfWeekString)
                            checked: root.incidenceWrapper.recurrenceData.type === 5 // Monthly on position
                            onTextChanged: if(checked) { root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek); }
                            onClicked: root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                        }
                    }


                    // Repeat end controls (visible on all recurrences)
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.FormData.label: i18n("Ends:")

                        QQC2.ComboBox {
                            id: endRecurType

                            Layout.fillWidth: currentIndex !== 1 //The end date combo box should fill the layout
                            // Recurrence duration returns -1 for never ending and 0 when the recurrence
                            // end date is set. Any number larger is the set number of recurrences
                            currentIndex: root.incidenceWrapper.recurrenceData.duration <= 0 ?
                                root.incidenceWrapper.recurrenceData.duration + 1 : 2

                            textRole: "displayName"
                            valueRole: "duration"
                            model: [
                                {displayName: i18n("Never"), duration: -1},
                                {displayName: i18n("On"), duration: 0},
                                {displayName: i18n("After"), duration: 1}
                            ]
                            delegate: Delegates.RoundedItemDelegate {
                                required property string displayName
                                required property int duration
                                text: displayName
                                onClicked: root.incidenceWrapper.setRecurrenceDataItem("duration", duration)
                            }
                            popup.z: 1000
                        }
                        Calendar.DateCombo {
                            id: recurEndDateCombo

                            Layout.fillWidth: true
                            visible: endRecurType.currentIndex === 1
                            onVisibleChanged: if (visible && isNaN(root.incidenceWrapper.recurrenceData.endDateTime.getTime())) {
                                root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date());
                            }

                            display: root.incidenceWrapper.recurrenceData.endDateDisplay
                            dateTime: root.incidenceWrapper.recurrenceData.endDateTime
                            onNewDateChosen: (day, month, year) => {
                                root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date(year, month - 1, day));
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: endRecurType.currentIndex === 2
                            onVisibleChanged: if (visible) { root.incidenceWrapper.setRecurrenceOccurrences(recurOccurrenceEndSpinbox.value) }

                            QQC2.SpinBox {
                                id: recurOccurrenceEndSpinbox

                                Layout.fillWidth: true
                                from: 1
                                value: root.incidenceWrapper.recurrenceData.duration
                                onValueChanged: if (visible) { root.incidenceWrapper.setRecurrenceOccurrences(value) }
                            }
                            QQC2.Label {
                                text: i18np("occurrence", "occurrences", recurOccurrenceEndSpinbox.value)
                            }
                        }
                    }

                    ColumnLayout {
                        Kirigami.FormData.label: i18n("Exceptions:")
                        Layout.fillWidth: true

                        QQC2.ComboBox {
                            id: exceptionAddButton

                            Layout.fillWidth: true
                            displayText: i18n("Add Recurrence Exception")

                            popup: Calendar.DatePopupSingleton.popup
                            onPressedChanged: if (pressed) {
                                Calendar.DatePopupSingleton.value = incidenceEndDateCombo.dateTime;
                                Calendar.DatePopupSingleton.popupParent = root;
                                Calendar.DatePopupSingleton.y = y + height;
                                connect.enabled = true;
                            }

                            Connections {
                                id: connect

                                target: Calendar.DatePopupSingleton
                                enabled: false

                                function onAccepted(): void {
                                    root.incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(Calendar.DatePopupSingleton.value);
                                    Calendar.DatePopupSingleton.close();
                                }

                                function onClosed(): void {
                                    enabled = false;
                                }
                            }
                        }

                        Repeater {
                            id: exceptionsRepeater
                            model: root.incidenceWrapper.recurrenceExceptionsModel

                            delegate: Delegates.RoundedItemDelegate {
                                id: exceptionDelegate

                                required property var date

                                text: date.toLocaleDateString(Qt.locale())

                                Layout.fillWidth: true

                                contentItem: RowLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Delegates.DefaultContentItem {
                                        itemDelegate: exceptionDelegate
                                        Layout.fillWidth: true
                                    }

                                    QQC2.Button {
                                        icon.name: "edit-delete-remove"
                                        onClicked: root.incidenceWrapper.recurrenceExceptionsModel.deleteExceptionDateTime(date)
                                    }
                                }
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Location:")
                    Layout.fillWidth: true

                    QQC2.ComboBox {
                        id: locationField

                        function openOrCloseLocationsPopup() {
                            if (locationsModel.count > 0 && locationTextField.text !== ""){
                                popup.open();
                            } else {
                                popup.close();
                            }
                        }

                        Layout.fillWidth: true
                        editable: true

                        contentItem: QQC2.TextField {
                            id: locationTextField

                            topPadding: 0
                            bottomPadding: 0
                            leftPadding: 0
                            rightPadding: locationField.indicator.width + locationField.spacing

                            placeholderText: i18n("Optional")
                            text: root.incidenceWrapper.location
                            onTextChanged: {
                                root.incidenceWrapper.location = text;
                                queryUpdateTimer.restart();
                            }

                            Keys.onPressed: locationField.openOrCloseLocationsPopup()

                            Timer {
                                id: queryUpdateTimer
                                interval: 300
                                onTriggered: locationsModel.query = root.incidenceWrapper.location;
                            }
                        }

                        model: GeocodeModel {
                            id: locationsModel
                            plugin: Plugin {
                                name: "osm"
                                PluginParameter {
                                    name: "osm.useragent"
                                    value: Application.name + "/" + Application.version + " (kde-pim@kde.org)"
                                }
                                PluginParameter {
                                    name: "osm.mapping.providersrepository.address"
                                    value: "https://autoconfig.kde.org/qtlocation/"
                                }
                            }
                            autoUpdate: true
                            onLocationsChanged: locationField.openOrCloseLocationsPopup()
                        }
                        delegate: Delegates.RoundedItemDelegate {
                            required property var locationData
                            text: locationData.address.text
                            onClicked: root.incidenceWrapper.location = locationData.address.text
                        }

                        QQC2.BusyIndicator {
                            height: parent.height
                            anchors.right: parent.right
                            anchors.rightMargin: parent.indicator.width
                            visible: locationsModel.status === GeocodeModel.Loading
                        }
                    }
                    QQC2.CheckBox {
                        id: mapVisibleCheckBox
                        text: i18n("Show map")
                        visible: Calendar.Config.enableMaps
                    }
                }

                ColumnLayout {
                    id: mapLayout
                    Layout.fillWidth: true
                    visible: Calendar.Config.enableMaps && mapVisibleCheckBox.checked

                    Loader {
                        id: mapLoader

                        Layout.fillWidth: true
                        height: Kirigami.Units.gridUnit * 16
                        asynchronous: true
                        active: visible

                        sourceComponent: Calendar.LocationMap {
                            id: map
                            selectMode: true
                            query: root.incidenceWrapper.location
                            onSelectedLocationAddress: address => root.incidenceWrapper.location = address
                        }
                    }
                }

                // Restrain the descriptionTextArea from getting too chonky
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: incidenceForm.wideMode ? Kirigami.Units.gridUnit * 25 : -1
                    Kirigami.FormData.label: i18n("Description:")

                    QQC2.TextArea {
                        id: descriptionTextArea

                        Layout.fillWidth: true
                        placeholderText: i18n("Optional")
                        text: root.incidenceWrapper.description
                        wrapMode: TextEdit.Wrap
                        onTextChanged: root.incidenceWrapper.description = text
                        Keys.onReturnPressed: event => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                submitAction.trigger();
                            } else {
                                event.accepted = false;
                            }
                        }
                    }
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Tags:")
                    Layout.fillWidth: true

                    QQC2.ComboBox {
                        Layout.fillWidth: true

                        enabled: count > 0
                        model: Akonadi.TagManager.tagModel
                        displayText: root.incidenceWrapper.categories.length > 0 ?
                            root.incidenceWrapper.categories.join(i18nc("List separator", ", ")) :
                            Kirigami.Settings.tabletMode ? i18n("Tap to set tags…") : i18n("Click to set tags…")

                        delegate: Delegates.RoundedItemDelegate {
                            id: delegate

                            required property int index
                            required property string name

                            text: name

                            checkable: true
                            checked: root.incidenceWrapper.categories.includes(name)
                            highlighted: false

                            topInset: index === 0 ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 2)
                            bottomInset: index === ListView.view.count - 1 ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 2)

                            contentItem: RowLayout {
                                QQC2.CheckBox {
                                    id: checkBox
                                    activeFocusOnTab: false

                                    checked: delegate.checked
                                    onCheckedChanged: if (delegate.checked !== checked) {
                                        delegate.checked = checked;
                                    }
                                }

                                Delegates.DefaultContentItem {
                                    itemDelegate: delegate
                                }
                            }

                            onCheckedChanged: {
                                root.incidenceWrapper.categories.includes(name) ?
                                    root.incidenceWrapper.categories = root.incidenceWrapper.categories.filter(tag => tag !== name) :
                                    root.incidenceWrapper.categories = [...root.incidenceWrapper.categories, name]
                                checkBox.checked = delegate.checked;

                            }
                        }
                    }
                    QQC2.Button {
                        text: i18n("Manage tags…")
                        onClicked: Calendar.CalendarApplication.action("open_tag_manager").trigger()
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }
                ColumnLayout {
                    id: remindersColumn

                    Kirigami.FormData.label: i18n("Reminders:")
                    Kirigami.FormData.labelAlignment: remindersRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: remindersRepeater

                        Layout.fillWidth: true

                        model: Calendar.RemindersModel {
                            id: remindersModel
                            incidence: root.incidenceWrapper.incidencePtr
                        }

                        delegate: Calendar.ReminderDelegate {
                            isTodo: incidenceForm.isTodo
                            remindersModel: remindersRepeater.model
                        }
                    }

                    QQC2.Button {
                        id: remindersButton

                        text: i18n("Add Reminder")
                        Layout.fillWidth: true

                        onClicked: remindersModel.addAlarm();
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }

                ColumnLayout {
                    id: attendeesColumn

                    Kirigami.FormData.label: i18n("Attendees:")
                    Kirigami.FormData.labelAlignment: attendeesRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: attendeesRepeater
                        model: root.incidenceWrapper.attendeesModel
                        // All of the alarms are handled within the delegates.
                        Layout.fillWidth: true

                        delegate: Kirigami.AbstractCard {
                            id: attendeeDelegate

                            required property int index
                            required property string email
                            required property string name
                            required property bool rsvp
                            required property int status

                            topPadding: Kirigami.Units.smallSpacing
                            bottomPadding: Kirigami.Units.smallSpacing

                            contentItem: Item {
                                implicitWidth: attendeeCardContent.implicitWidth
                                implicitHeight: attendeeCardContent.implicitHeight

                                GridLayout {
                                    id: attendeeCardContent

                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        right: parent.right
                                        //IMPORTANT: never put the bottom margin
                                    }

                                    columns: 6
                                    rows: 4

                                    QQC2.Label{
                                        Layout.row: 0
                                        Layout.column: 0
                                        text: i18n("Name:")
                                    }
                                    QQC2.TextField {
                                        Layout.fillWidth: true
                                        Layout.row: 0
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        placeholderText: i18n("Optional")
                                        text: attendeeDelegate.name
                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
                                                                                                    text,
                                                                                                    Calendar.AttendeesModel.NameRole)
                                    }

                                    QQC2.Button {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.column: 5
                                        Layout.row: 0
                                        icon.name: "edit-delete-remove"
                                        onClicked: root.incidenceWrapper.attendeesModel.deleteAttendee(attendeeDelegate.index);
                                    }

                                    QQC2.Label {
                                        Layout.row: 1
                                        Layout.column: 0
                                        text: i18n("Email:")
                                    }
                                    QQC2.TextField {
                                        Layout.fillWidth: true
                                        Layout.row: 1
                                        Layout.column: 1
                                        Layout.columnSpan: 4
                                        placeholderText: i18n("Required")
                                        text: attendeeDelegate.email
                                        onTextChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
                                                                                                    text,
                                                                                                    Calendar.AttendeesModel.EmailRole)
                                    }
                                    QQC2.Label {
                                        Layout.row: 2
                                        Layout.column: 0
                                        text: i18n("Status:")
                                        visible: root.editMode
                                    }
                                    QQC2.ComboBox {
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        Layout.column: 1
                                        Layout.columnSpan: 2
                                        model: root.incidenceWrapper.attendeesModel.attendeeStatusModel
                                        textRole: "display"
                                        valueRole: "value"
                                        currentIndex: attendeeDelegate.status // role of parent
                                        onCurrentValueChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
                                                                                                            currentValue,
                                                                                                            Calendar.AttendeesModel.StatusRole)

                                        popup.z: 1000
                                        visible: root.editMode
                                    }
                                    QQC2.CheckBox {
                                        Layout.fillWidth: true
                                        Layout.row: 2
                                        Layout.column: 3
                                        Layout.columnSpan: 2
                                        text: i18n("Request RSVP")
                                        checked: attendeeDelegate.rsvp
                                        onCheckedChanged: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
                                                                                                       checked,
                                                                                                       Calendar.AttendeesModel.RSVPRole)
                                        visible: root.editMode
                                    }
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: attendeesButton
                        text: i18n("Add Attendee")
                        Layout.fillWidth: true

                        onClicked: attendeeAddChoices.open()

                        QQC2.Menu {
                            id: attendeeAddChoices
                            width: attendeesButton.width
                            y: parent.height // Y is relative to parent

                            QQC2.MenuItem {
                                text: i18n("Choose from Contacts")
                                onClicked: pageStack.push(contactsPage)
                            }
                            QQC2.MenuItem {
                                text: i18n("Fill in Manually")
                                onClicked: root.incidenceWrapper.attendeesModel.addAttendee();
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                }

                ColumnLayout {
                    id: attachmentsColumn

                    Kirigami.FormData.label: i18n("Attachments:")
                    Kirigami.FormData.labelAlignment: attachmentsRepeater.count ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.fillWidth: true

                    Repeater {
                        id: attachmentsRepeater
                        model: root.incidenceWrapper.attachmentsModel
                        delegate: Delegates.RoundedItemDelegate {
                            id: attachmentDelegate

                            required property string iconName
                            required property string attachmentLabel
                            required property string uri

                            icon.name: iconName
                            text: attachmentLabel

                            onClicked: Qt.openUrlExternally(uri)

                            contentItem: RowLayout {
                                Delegates.DefaultContentItem {
                                    itemDelegate: attachmentDelegate
                                    Layout.fillWidth: true
                                }

                                QQC2.Button {
                                    icon.name: "edit-delete-remove"
                                    onClicked: root.incidenceWrapper.attachmentsModel.deleteAttachment(attachmentDelegate.uri)
                                }
                            }
                        }
                    }

                    QQC2.Button {
                        id: attachmentsButton
                        text: i18n("Add Attachment")
                        Layout.fillWidth: true
                        onClicked: attachmentFileDialog.open();

                        FileDialog {
                            id: attachmentFileDialog

                            title: i18n("Add an attachment")
                            currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
                            onAccepted: root.incidenceWrapper.attachmentsModel.addAttachment(selectedFile)
                        }
                    }
                }
            }
        }
    }
}
