// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import QtLocation
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

FormCard.FormCardPage {
    id: root

    signal cancel

    // Setting the incidenceWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property var incidenceWrapper
    property bool editMode: false

    property bool validDates: {
        if (!incidenceWrapper) {
            return false;
        }
        if (incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
            return editorLoader.active && editorLoader.item.validEndDate
        } else {
            return editorLoader.active && editorLoader.item.validFormDates && (incidenceWrapper.allDay || incidenceWrapper.incidenceStart <= incidenceWrapper.incidenceEnd)
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

    footer: ColumnLayout {
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.DialogButtonBox {
            Layout.fillWidth: true

            standardButtons: QQC2.DialogButtonBox.Cancel

            QQC2.Button {
                icon.name: root.editMode ? "document-save" : "list-add"
                text: root.editMode ? i18n("Save") : i18n("Add")
                enabled: root.validDates && root.incidenceWrapper.summary && root.incidenceWrapper.collectionId
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: root.cancel()
            onAccepted: {
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

                    Calendar.CalendarManager.addIncidence(root.incidenceWrapper);
                }
                root.cancel();
            }
        }
    }


    Loader {
        active: root.incidenceWrapper !== undefined
        Layout.fillWidth: true
        sourceComponent: ColumnLayout {
	        spacing: 0

            FormCard.FormCard {
                id: incidenceForm

                property bool validStartDate: incidenceForm.isTodo ?
                    incidenceStartDate.validDate || !incidenceStartCheckBox.checked :
                    incidenceStartDate.validDate
                property bool validEndDate: incidenceForm.isTodo ?
                    incidenceEndDate.validDate || !incidenceEndCheckBox.checked :
                    incidenceEndDate.validDate
                property bool validFormDates: validStartDate && (validEndDate || root.incidenceWrapper.allDay)

                property date todayDate: new Date()
                property bool isTodo: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo
                property bool isJournal: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeJournal

                Layout.topMargin: Kirigami.Units.gridUnit

                FormCard.FormTextFieldDelegate {
                    id: summaryField

                    label: i18n("Summary")
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

                FormCard.FormDelegateSeparator {}

                FormCard.FormComboBoxDelegate {
                    id: locationField

                    text: i18nc("@label", "Location")
                    editable: true

                    function openOrCloseLocationsPopup() {
                        if (locationsModel.count > 0 && locationTextField.text !== ""){
                            popup.open();
                        } else {
                            popup.close();
                        }
                    }

                    valueRole: "locationData"
                    displayText: currentValue.address.text
                    // placeholderText: i18n("Optional")

                    onEditTextChanged: {
                        root.incidenceWrapper.location = text;
                        queryUpdateTimer.restart();
                    }

                    Timer {
                        id: queryUpdateTimer
                        interval: 300
                        onTriggered: {
                            locationsModel.query = root.incidenceWrapper.location;
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
                    onCurrentValueChanged: root.incidenceWrapper.location = currentValue.address.text
                    Keys.onPressed: locationField.openOrCloseLocationsPopup()

                    QQC2.BusyIndicator {
                        height: parent.height
                        anchors.right: parent.right
                        visible: locationsModel.status === GeocodeModel.Loading
                    }
                }

                FormCard.AbstractFormDelegate {
                    id: mapDelegate
                    visible: Calendar.Config.enableMaps

                    contentItem: Loader {
                        id: mapLoader

                        active: mapDelegate.visible
                        asynchronous: true

                        sourceComponent: Calendar.LocationMap {
                            id: map
                            selectMode: true
                            query: root.incidenceWrapper.location
                            onSelectedLocationAddress: address => root.incidenceWrapper.location = address
                        }
                    }
                }

                FormCard.FormDelegateSeparator {}

                Akonadi.FormCollectionComboBox {
                    id: calendarCombo

                    text: i18nc("@label", "Calendar")

                    mimeTypeFilter: if (root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeEvent) {
                        return [Akonadi.MimeTypes.calendar]
                    } else if (root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
                        return [Akonadi.MimeTypes.todo]
                    }
                    accessRightsFilter: Akonadi.Collection.CanCreateItem

                    defaultCollectionId: {
                        if (root.incidenceWrapper.collectionId === -1) {
                            if ((incidenceForm.isTodo && Calendar.Config.lastUsedTodoCollection === -1) ||
                                (!incidenceForm.isTodo && Calendar.Config.lastUsedEventCollection === -1)) {
                                return calendarCombo.model.data(index(calendarCombo.currentIndex, 0), Akonadi.EntityTreeModel.CollectionIdRole);
                            }
                            return incidenceForm.isTodo ? Calendar.Config.lastUsedTodoCollection : Calendar.Config.lastUsedEventCollection;
                        }
                        return root.incidenceWrapper.collectionId;
                    }

                    onCurrentIndexChanged: {
                        if (calendarCombo.model.rowCount() === 0) {
                            return;
                        }
                        let selectedModelIndex = calendarCombo.model.index(currentIndex, 0);
                        let selectedCollection = calendarCombo.model.data(selectedModelIndex, Akonadi.EntityTreeModel.CollectionRole);
                        root.incidenceWrapper.setCollection(selectedCollection)
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Task")
                visible: incidenceForm.isTodo
            }

            FormCard.FormCard {
                visible: incidenceForm.isTodo

                FormCard.AbstractFormDelegate {
                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Completion")
                                elide: Text.ElideRight
                                color: root.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                Accessible.ignored: true
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignRight
                                text: i18n("%1%", slider.value)
                            }
                        }

                        QQC2.Slider {
                            id: slider
                            Layout.fillWidth: true
                            orientation: Qt.Horizontal
                            from: 0
                            to: 100.0
                            stepSize: 10.0
                            value: root.incidenceWrapper.todoPercentComplete
                            onValueChanged: root.incidenceWrapper.todoPercentComplete = value
                        }
                    }
                }

                FormCard.FormDelegateSeparator {}

                FormCard.FormComboBoxDelegate {
                    text: i18n("Priority")
                    model: [
                        {display: i18n("Unassigned"), value: 0},
                        {display: i18n("1 (Highest Priority)"), value: 1},
                        {display: i18n("2"), value: 2},
                        {display: i18n("3"), value: 3},
                        {display: i18n("4"), value: 4},
                        {display: i18n("5 (Medium Priority)"), value: 5},
                        {display: i18n("6"), value: 6},
                        {display: i18n("7"), value: 7},
                        {display: i18n("8"), value: 8},
                        {display: i18n("9 (Lowest Priority)"), value: 9}
                    ]

                    currentIndex: root.incidenceWrapper.priority
                    onCurrentValueChanged: root.incidenceWrapper.priority = currentValue
                    visible: incidenceForm.isTodo

                    textRole: "display"
                    valueRole: "value"
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Start")

                trailing: QQC2.CheckBox {
                    id: allDayCheckBox

                    text: i18n("All day")
                    visible: !incidenceForm.isTodo
                    enabled: !incidenceForm.isTodo || !isNaN(root.incidenceWrapper.incidenceStart.getTime()) || !isNaN(root.incidenceWrapper.incidenceEnd.getTime())
                    onEnabledChanged: if (!enabled) root.incidenceWrapper.allDay = false
                    checked: root.incidenceWrapper.allDay
                    onToggled: {
                        if (!checked) {
                            root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour();
                        }
                        root.incidenceWrapper.allDay = checked;
                    }
                }
            }

            FormCard.FormCard {
                // TODO: Start for todos?
                FormCard.FormDateTimeDelegate {
                    id: incidenceStartDate

                    readonly property bool validDate: !isNaN(value.getTime())

                    visible: !incidenceForm.isTodo || (incidenceForm.isTodo && !isNaN(root.incidenceWrapper.incidenceStart.getTime()))
                    dateTimeDisplay: allDayCheckBox.checked ? FormCard.FormDateTimeDelegate.Date : FormCard.FormDateTimeDelegate.DateTime
                    initialValue: root.incidenceWrapper.incidenceStart
                    onValueChanged: () => {
                        root.incidenceWrapper.setIncidenceStartDate(value.getDate(), value.getMonth(), value.getFullYear())
                    }
                    // display: root.incidenceWrapper.incidenceStartDateDisplay
                    // dateTime: root.incidenceWrapper.incidenceStart
                    // onNewDateChosen: (day, month, year) => {
                    //     root.incidenceWrapper.setIncidenceStartDate(day, month, year)
                    // }
                    // onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceStartTime(hours, minutes)
                    // timeZoneOffset: root.incidenceWrapper.startTimeZoneUTCOffsetMins
                    // enabled: !allDay    CheckBox.checked && (!incidenceForm.isTodo || incidenceStartCheckBox.checked)
                    // display: root.incidenceWrapper.incidenceEndTimeDisplay
                    // dateTime: root.incidenceWrapper.incidenceStart
                    //

                    Connections {
                        target: root.incidenceWrapper

                        function onIncidenceStartChanged(): void {
                            if (!isNaN(root.incidenceWrapper.incidenceStart.getTime())) {
                                incidenceStartDate.value = root.incidenceWrapper.incidenceStart;
                            }
                        }
                    }
                }
            }

            FormCard.FormHeader {
                title: incidenceForm.isTodo ? i18nc("@title:group", "Due") : i18nc("@title:group", "End")

                trailing: QQC2.CheckBox {
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
            }

            FormCard.FormCard {
                FormCard.FormDateTimeDelegate {
                    id: incidenceEndDate

                    readonly property bool validDate: !isNaN(value.getTime())

                    visible: !incidenceForm.isJournal || incidenceForm.isTodo
                    enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)

                    dateTimeDisplay: incidenceStartDate.dateTimeDisplay

                    initialValue: root.incidenceWrapper.incidenceEnd
                    // onNewDateChosen: (day, month, year) => {
                        // root.incidenceWrapper.setIncidenceEndDate(day, month, year)
                    // }
                    // timeZoneOffset: root.incidenceWrapper.endTimeZoneUTCOffsetMins
                    // display: root.incidenceWrapper.incidenceEndTimeDisplay
                    // dateTime: root.incidenceWrapper.incidenceEnd
                    // onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceEndTime(hours, minutes)
                    // enabled: (!incidenceForm.isTodo && !allDayCheckBox.checked) || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                    // visible: !allDayCheckBox.checked
                    //
                    Connections {
                        target: root.incidenceWrapper

                        function onIncidenceEndChanged(): void {
                            if (!isNaN(root.incidenceWrapper.incidenceEnd.getTime())) {
                                incidenceEndDate.value = root.incidenceWrapper.incidenceEnd;
                            }
                        }
                    }
                }

                FormCard.FormDelegateSeparator {}

                FormCard.FormComboBoxDelegate {
                    id: timeZoneComboBox
                    text: i18n("Timezone:")

                    model: Calendar.TimeZoneListModel {
                        id: timeZonesModel
                    }
                    textRole: "displayName"
                    valueRole: "id"
                    currentIndex: model ? timeZonesModel.getTimeZoneRow(root.incidenceWrapper.timeZone) : -1
                    onCurrentValueChanged: root.incidenceWrapper.timeZone = currentValue
                    enabled: !incidenceForm.isTodo || (incidenceForm.isTodo && incidenceEndCheckBox.checked)
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title", "Repeat")
            }
            FormCard.FormCard {
                id: customRecurrenceLayout

                // TODO visible: repeatComboBox.currentIndex > 0 // Not "Never" index
                FormCard.FormComboBoxDelegate {
                    id: repeatComboBox
                    text: i18n("Repeat:")

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

                    onCurrentValueChanged: if (currentValue >= 0) {
                        root.incidenceWrapper.setRegularRecurrence(currentValue)
                    } else {
                        root.incidenceWrapper.clearRecurrences();
                    }
                }

                function setOccurrence() {
                    root.incidenceWrapper.setRegularRecurrence(recurScaleRuleCombobox.currentValue, recurFreqRuleSpinbox.value);

                    if(recurScaleRuleCombobox.currentValue === Calendar.IncidenceWrapper.Weekly) {
                        weekdayCheckboxRepeater.setWeekdaysRepeat();
                    }
                }

                FormCard.AbstractFormDelegate {
                    visible: repeatComboBox.currentIndex === 5
                    contentItem: RowLayout {
                        QQC2.Label {
                            text: i18n("Every:")
                        }

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

                            textRole: "displayName"
                            valueRole: "interval"
                            onCurrentValueChanged: if(visible) {
                                customRecurrenceLayout.setOccurrence();
                                repeatComboBox.currentIndex = 5; // Otherwise resets to default daily/weekly/etc.
                            }
                            currentIndex: {
                                if(root.incidenceWrapper.recurrenceData.type === undefined) {
                                    return 0;
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
                                        return 0;
                                }
                            }

                            model: [
                                {key: "day", displayName: i18np("day", "days", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Daily},
                                {key: "week", displayName: i18np("week", "weeks", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Weekly},
                                {key: "month", displayName: i18np("month", "months", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Monthly},
                                {key: "year", displayName: i18np("year", "years", recurFreqRuleSpinbox.value), interval: Calendar.IncidenceWrapper.Yearly},
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
                }

                QQC2.ButtonGroup {
                    buttons: monthlyRecurRadioColumn.children
                }

                FormCard.AbstractFormDelegate {
                    visible: recurScaleRuleCombobox.currentValue === Calendar.IncidenceWrapper.Monthly && repeatComboBox.currentIndex === 5
                    contentItem: ColumnLayout {
                        id: monthlyRecurRadioColumn

                        QQC2.Label {
                            text: i18n("On:")
                        }

                        Layout.fillWidth: true

                        QQC2.RadioButton {
                            property int dateOfMonth: incidenceStartDate.value.getDate()

                            text: i18nc("%1 is the day number of month", "The %1 of each month", Calendar.LabelUtils.numberToString(dateOfMonth))

                            checked: root.incidenceWrapper.recurrenceData.type === 6 // Monthly on day (1st of month)
                            onClicked: customRecurrenceLayout.setOccurrence()
                        }
                        QQC2.RadioButton {
                            property int dayOfWeek: incidenceStartDate.value.getDay() > 0 ?
                                                    incidenceStartDate.value.getDay() - 1 :
                                                    7 // C++ Qt day of week index goes Mon-Sun, 0-7
                            property int weekOfMonth: Math.ceil((incidenceStartDate.value.getDate() + 6 - incidenceStartDate.value.getDay()) / 7);
                            property string dayOfWeekString: Qt.locale().dayName(incidenceStartDate.value.getDay())

                            text: i18nc("the weekOfMonth dayOfWeekString of each month", "The %1 %2 of each month", Calendar.LabelUtils.numberToString(weekOfMonth), dayOfWeekString)
                            checked: root.incidenceWrapper.recurrenceData.type === 5 // Monthly on position
                            onTextChanged: if(checked) { root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek); }
                            onClicked: root.incidenceWrapper.setMonthlyPosRecurrence(weekOfMonth, dayOfWeek)
                        }
                    }
                }

                FormCard.FormComboBoxDelegate {
                    id: endRecurType

                    visible: repeatComboBox.currentIndex !== 0
                    text: i18n("Ends:")
                    // ?? Layout.fillWidth: currentIndex !== 1 //The end date combo box should fill the layout
                    // Recurrence duration returns -1 for never ending and 0 when the recurrence
                    // end date is set. Any number larger is the set number of recurrences
                    currentIndex: root.incidenceWrapper.recurrenceData.duration <= 0 ?
                        root.incidenceWrapper.recurrenceData.duration + 1 : 2
                    onCurrentValueChanged: root.incidenceWrapper.setRecurrenceDataItem("duration", duration)
                    textRole: "displayName"
                    valueRole: "duration"
                    model: [
                        {displayName: i18n("Never"), duration: -1},
                        {displayName: i18n("On"), duration: 0},
                        {displayName: i18n("After"), duration: 1}
                    ]

                }

                FormCard.FormDateTimeDelegate {
                    id: recurEndDateCombo

                    dateTimeDisplay: FormCard.FormDateTimeDelegate.Date

                    visible: endRecurType.visible && endRecurType.currentIndex === 1
                    // onVisibleChanged: if (visible && isNaN(root.incidenceWrapper.recurrenceData.endDateTime.getTime())) {
                    //     root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date());
                    // }

                    // display: root.incidenceWrapper.recurrenceData.endDateDisplay
                    // dateTime: root.incidenceWrapper.recurrenceData.endDateTime
                    // onNewDateChosen: (day, month, year) => {
                    //     root.incidenceWrapper.setRecurrenceDataItem("endDateTime", new Date(year, month - 1, day));
                    // }
                }

                FormCard.FormSpinBoxDelegate {
                    id: recurOccurrenceEndSpinbox
                    label: i18nc("@label:spinbox", "Ends after:")
                    textFromValue: function(value: int): string {
                        return i18np("%1 occurrence", "%1 occurrences", value)
                    }
                    visible: endRecurType.currentIndex === 2
                    onVisibleChanged: if (visible) { root.incidenceWrapper.setRecurrenceOccurrences(recurOccurrenceEndSpinbox.value) }
                    from: 1
                    value: root.incidenceWrapper.recurrenceData.duration
                    onValueChanged: if (visible) { root.incidenceWrapper.setRecurrenceOccurrences(value) }
                }

                FormCard.FormTextDelegate {
                    text: i18n("Exceptions:")
                    visible: repeatComboBox.currentIndex !== 0
                    trailing: QQC2.Button {
                        text: i18nc("@action:button", "Add")
                        icon.name: "list-add"
                        onClicked: {
                            Calendar.DatePopupSingleton.value = incidenceEndDateCombo.value;
                            Calendar.DatePopupSingleton.popupParent = root;
                            Calendar.DatePopupSingleton.y = y + height;
                            Calendar.DatePopupSingleton.open()
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
                }

                Repeater {
                    model: root.incidenceWrapper.recurrenceExceptionsModel

                    delegate: FormCard.FormTextDelegate {
                        id: exceptionDelegate

                        required property date date

                        leftPadding: Kirigami.Units.largeSpacing * 4

                        text: date.toLocaleDateString(Qt.locale())
                        trailing: QQC2.Button {
                            icon.name: "edit-delete-remove"
                            onClicked: root.incidenceWrapper.recurrenceExceptionsModel.deleteExceptionDateTime(date)
                        }
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Attendees")
                trailing: QQC2.ToolButton {
                    id: attendeesButton

                    text: i18n("Add Attendee")
                    icon.name: 'list-add-symbolic'

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

            FormCard.FormCard {
                FormCard.FormPlaceholderMessageDelegate {
                    text: i18nc("@info:placeholder", "There are no attendees")
                    visible: attendeesRepeater.count === 0
                }

                Repeater {
                    id: attendeesRepeater

                    model: root.incidenceWrapper.attendeesModel
                    // All of the alarms are handled within the delegates.
                    Layout.fillWidth: true

                    delegate: FormCard.AbstractFormDelegate {
                        id: attendeeDelegate

                        required property int index
                        required property string email
                        required property string name
                        required property bool rsvp
                        required property int status

                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: Kirigami.Units.smallSpacing

                        background: null
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
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Reminders")
                trailing: QQC2.ToolButton {
                    text: i18n("Add Reminder")
                    icon.name: 'list-add-symbolic'
                    onClicked: remindersModel.addAlarm()
                }
            }

            FormCard.FormCard {
                FormCard.FormPlaceholderMessageDelegate {
                    text: i18nc("@info:placeholder", "There are no attendees")
                    visible: remindersRepeater.count === 0
                }

                Repeater {
                    id: remindersRepeater

                    model: Calendar.RemindersModel {
                        id: remindersModel
                        incidence: root.incidenceWrapper.incidencePtr
                    }

                    delegate: Calendar.ReminderDelegate {
                        isTodo: incidenceForm.isTodo
                        remindersModel: remindersRepeater.model
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Tags")
                trailing: QQC2.ToolButton {
                    text: i18n("Manage tags…")
                    icon.name: 'tag-symbolic'
                    onClicked: Calendar.CalendarApplication.action("open_tag_manager").trigger()
                }
            }

            FormCard.FormCard {
                FormCard.AbstractFormDelegate {
                    background: null
                    contentItem: QQC2.ComboBox {
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
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Attachments")
                trailing: QQC2.ToolButton {
                    text: i18n("Add Attachment")
                    icon.name: "list-add-symbolic"
                    onClicked: attachmentFileDialog.open();

                    FileDialog {
                        id: attachmentFileDialog

                        title: i18n("Add an attachment")
                        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
                        onAccepted: root.incidenceWrapper.attachmentsModel.addAttachment(selectedFile)
                    }
                }
            }

            FormCard.FormCard {
                FormCard.FormPlaceholderMessageDelegate {
                    text: i18nc("@info:placeholder", "There are no attachments")
                    visible: attachmentsRepeater.count === 0
                }

                Repeater {
                    id: attachmentsRepeater
                    model: root.incidenceWrapper.attachmentsModel
                    delegate: FormCard.AbstractFormDelegate {
                        id: attachmentDelegate
     
                        required property string iconName
                        required property string attachmentLabel
                        required property string uri
     
                        icon.name: iconName
                        text: attachmentLabel
     
                        onClicked: Qt.openUrlExternally(uri)
     
                        contentItem: RowLayout {
                            QQC2.Label {
                                text: attachmentDelegate.attachmentLabel
                            }
     
                            QQC2.Button {
                                icon.name: "edit-delete-remove"
                                onClicked: root.incidenceWrapper.attachmentsModel.deleteAttachment(attachmentDelegate.uri)
                            }
                        }
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Note")
            }

            FormCard.FormCard {
                QQC2.TextArea {
                    text: root.incidenceWrapper.description
                    wrapMode: TextEdit.Wrap
                    onTextChanged: root.incidenceWrapper.description = text
                    background.visible: activeFocus

                    leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                    rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                    topPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                    bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

                    Layout.preferredHeight: Kirigami.Units.gridUnit * 6

                    Keys.onTabPressed: nextItemInFocusChain().forceActiveFocus()

                    Keys.onReturnPressed: event => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            submitAction.trigger();
                        } else {
                            event.accepted = false;
                        }
                    }
                    Layout.fillWidth: true
                }
            }
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
}
