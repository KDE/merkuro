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
import org.kde.merkuro.components as MerkuroComponents
import org.kde.akonadi as Akonadi

FormCard.FormCardPage {
    id: root

    signal cancel

    // Setting the incidenceWrapper here and now causes some *really* weird behaviour.
    // Set it after this component has already been instantiated.
    property Calendar.IncidenceWrapper incidenceWrapper
    property bool editMode: false
    readonly property bool saving: editorBackend.saving

    onBackRequested: event => {
        if (editorBackend.saving) {
            event.accepted = true;
        }
    }

    Calendar.CalendarEditorBackend {
        id: editorBackend
        calendarManager: Calendar.CalendarManager

        onFinished: {
            if (!root.editMode) {
                if (root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
                    Calendar.Config.lastUsedTodoCollection = root.incidenceWrapper.collectionId;
                } else {
                    Calendar.Config.lastUsedEventCollection = root.incidenceWrapper.collectionId;
                }
                Calendar.Config.save();
            }
            root.cancel();
        }
    }

    function save(): void {
        if (!root.validDates || editorBackend.saving || root.incidenceWrapper.hasExternalChanges) {
            return;
        }
        if (!root.editMode && root.incidenceWrapper.collectionId < 0) {
            root.incidenceWrapper.collectionId = editorLoader.item.calendarCombo.currentValue;
            if (root.incidenceWrapper.collectionId < 0) {
                root.incidenceWrapper.collectionId = editorLoader.item.calendarCombo.defaultCollectionId;
            }
        }
        editorBackend.save(root.incidenceWrapper, root.editMode);
    }

    Components.MessageDialog {
        id: reloadDialog
        objectName: "reloadIncidenceDialog"
        dialogType: Components.MessageDialog.Warning
        title: i18nc("@title:window", "Reload Incidence")
        subtitle: i18n("Reloading will discard your unsaved changes and load the latest version.")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        onAccepted: editorBackend.reload(root.incidenceWrapper)
    }

    readonly property bool validDates: {
        if (!incidenceWrapper) {
            return false;
        }
        if (incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
            return editorLoader.status === Loader.Ready && editorLoader.item.validEndDate
        } else {
            return editorLoader.status === Loader.Ready && editorLoader.item.validFormDates && (incidenceWrapper.allDay || root.incidenceWrapper.incidenceStart.msecsTo(root.incidenceWrapper.incidenceEnd) >= 0)
        }
    }

    title: if (incidenceWrapper) {
        editMode ? i18nc("%1 is incidence type", "Edit %1", incidenceWrapper.incidenceTypeStr) :
            i18nc("%1 is incidence type", "Add %1", incidenceWrapper.incidenceTypeStr);
    } else {
        "";
    }

    header: ColumnLayout {
        spacing: 0

        Components.Banner {
            objectName: "externalChangeMessage"
            Layout.fillWidth: true
            visible: root.incidenceWrapper && root.incidenceWrapper.hasExternalChanges
            type: Kirigami.MessageType.Warning
            text: root.incidenceWrapper && root.incidenceWrapper.incidenceDeleted
                ? i18n("This incidence was deleted. Your unsaved changes have been kept.")
                : i18n("This incidence changed outside this editor. Your unsaved changes have been kept. Reload the latest version before saving.")
            actions: Kirigami.Action {
                text: i18nc("@action:button", "Reload")
                icon.name: "view-refresh"
                enabled: !editorBackend.saving && root.incidenceWrapper && !root.incidenceWrapper.incidenceDeleted
                visible: root.incidenceWrapper && !root.incidenceWrapper.incidenceDeleted
                onTriggered: reloadDialog.open()
            }
        }

        Components.Banner {
            objectName: "saveErrorMessage"
            Layout.fillWidth: true
            visible: editorBackend.errorMessage.length > 0
            type: Kirigami.MessageType.Error
            text: editorBackend.errorMessage
        }

        Components.Banner {
            id: invalidDateMessage

            Layout.fillWidth: true
            visible: !root.validDates && root.incidenceWrapper !== null && editorLoader.status === Loader.Ready
            type: Kirigami.MessageType.Error
            // Specify what the problem is to aid user
            text: if (!root.incidenceWrapper || !editorLoader.active) {
                return '';
            } else {
                if (incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo) {
                    return i18n("Invalid dates provided.");
                } else {
                    if (!editorLoader.item.validFormDates) {
                        return i18n("Invalid dates provided.");
                    }
                    return i18n("End date cannot be before start date.");
                }
            }
        }
    }

    footer: ColumnLayout {
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.DialogButtonBox {
            Layout.fillWidth: true
            enabled: !editorBackend.saving

            standardButtons: QQC2.DialogButtonBox.Cancel

            QQC2.Button {
                objectName: "saveButton"
                icon.name: root.editMode ? "document-save" : "list-add"
                text: root.editMode ? i18n("Save") : i18n("Add")
                enabled: !editorBackend.saving && root.validDates && !root.incidenceWrapper.hasExternalChanges && root.incidenceWrapper.summary.trim().length > 0
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: if (!editorBackend.saving) root.cancel()
            onAccepted: root.save()
        }
    }


    Loader {
        id: editorLoader

        active: root.incidenceWrapper !== null
        enabled: !editorBackend.saving

        Layout.fillWidth: true

        sourceComponent: ColumnLayout {
            id: incidenceForm
            property alias calendarCombo: calendarCombo

	        spacing: 0

            readonly property bool validStartDate: incidenceForm.isTodo ?
                incidenceStartDateCombo.validDate || !incidenceStartCheckBox.checked :
                incidenceStartDateCombo.validDate
            readonly property bool validEndDate: incidenceForm.isTodo ?
                incidenceEndDateCombo.validDate || !incidenceEndCheckBox.checked :
                incidenceEndDateCombo.validDate
            readonly property bool validFormDates: validStartDate && (validEndDate || root.incidenceWrapper.allDay)
            property bool isTodo: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeTodo
            property bool isJournal: root.incidenceWrapper.incidenceType === Calendar.IncidenceWrapper.TypeJournal

            function clearAllDayForUndatedTodo(): void {
                if (isTodo && !root.incidenceWrapper.incidenceStart.isValid && !root.incidenceWrapper.incidenceEnd.isValid) {
                    root.incidenceWrapper.allDay = false;
                }
            }

            FormCard.FormCard {
                Layout.topMargin: Kirigami.Units.gridUnit

                FormCard.FormTextFieldDelegate {
                    id: summaryField
                    objectName: "summaryField"

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
                    onTextEdited: root.incidenceWrapper.summary = text
                }

                FormCard.FormDelegateSeparator {}

                // Todo make this again a combobox delegate
                FormCard.FormTextFieldDelegate {
                    id: locationField

                    label: i18nc("@label", "Location")
                    text: root.incidenceWrapper.location
                    onTextEdited: {
                        root.incidenceWrapper.location = text;
                    }

                    /*
                    editable: true

                    function openOrCloseLocationsPopup(): void {
                        if (locationsModel.count > 0 && locationTextField.text !== ""){
                            locationField.clicked();
                        } else {
                            locationField.closeDialog();
                        }
                    }

                    editText: root.incidenceWrapper.location
                    valueRole: "locationData"
                    // placeholderText: i18n("Optional")

                    onTextEdited: {
                        root.incidenceWrapper.location = text;
                        //queryUpdateTimer.restart();
                    }

                    /*
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
                    onActivated: root.incidenceWrapper.location = currentValue.address.text
                    Keys.onPressed: locationField.openOrCloseLocationsPopup()

                    QQC2.BusyIndicator {
                        height: parent.height
                        anchors.right: parent.right
                        visible: locationsModel.status === GeocodeModel.Loading
                    }*/
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

                    onActivated: {
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
                            objectName: "completionSlider"
                            Layout.fillWidth: true
                            orientation: Qt.Horizontal
                            from: 0
                            to: 100.0
                            stepSize: 10.0
                            value: root.incidenceWrapper.todoPercentComplete
                            onMoved: root.incidenceWrapper.todoPercentComplete = value
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
                    onActivated: root.incidenceWrapper.priority = currentValue
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
                    enabled: !incidenceForm.isTodo || root.incidenceWrapper.incidenceStart.isValid || root.incidenceWrapper.incidenceEnd.isValid
                    checked: root.incidenceWrapper.allDay
                    onToggled: {
                        if (!checked) {
                            root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour(
                                root.incidenceWrapper.incidenceStart.isValid,
                                root.incidenceWrapper.incidenceEnd.isValid,
                            );
                        }
                        root.incidenceWrapper.allDay = checked;
                    }
                }
            }

            Connections {
                target: root.incidenceWrapper
                function onIncidenceStartChanged(): void {
                    incidenceStartDateCombo.dateTime = root.incidenceWrapper.incidenceStart;
                            incidenceStartTimeCombo.dateTime = root.incidenceWrapper.incidenceStart;
                    incidenceStartTimeCombo.display = root.incidenceWrapper.incidenceStart.toLocaleTimeString(Locale.NarrowFormat);
                }

                function onIncidenceEndChanged() {
                    incidenceEndDateCombo.dateTime = root.incidenceWrapper.incidenceEnd;
                            incidenceEndTimeCombo.dateTime = root.incidenceWrapper.incidenceEnd;
                    incidenceEndTimeCombo.display = root.incidenceWrapper.incidenceEnd.toLocaleTimeString(Locale.NarrowFormat);
                }
            }

            FormCard.FormCard {
                FormCard.AbstractFormDelegate {
                    background: null
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.CheckBox {
                            id: incidenceStartCheckBox
                            objectName: "incidenceStartCheckBox"

                            property MerkuroComponents.KDateTime oldDate: MerkuroComponents.KDateTimeFactory.invalid()

                            checked: root.incidenceWrapper.incidenceStart.isValid
                            onClicked: {
                                if (!checked && incidenceForm.isTodo) {
                                    oldDate = root.incidenceWrapper.incidenceStart
                                    root.incidenceWrapper.incidenceStart = MerkuroComponents.KDateTimeFactory.invalid()
                                } else if(incidenceForm.isTodo && oldDate.isValid) {
                                    root.incidenceWrapper.incidenceStart = oldDate
                                } else if(incidenceForm.isTodo) {
                                    root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour(true, false);
                                }
                                incidenceForm.clearAllDayForUndatedTodo();
                            }
                            visible: incidenceForm.isTodo
                        }

                        Calendar.DateCombo {
                            id: incidenceStartDateCombo

                            Layout.fillWidth: true
                            display: root.incidenceWrapper.incidenceStart.toLocaleDateString(Locale.NarrowFormat)
                            dateTime: root.incidenceWrapper.incidenceStart
                            onNewDateChosen: (day, month, year) => {
                                root.incidenceWrapper.setIncidenceStartDate(day, month, year)
                            }

                            enabled: incidenceStartCheckBox.checked
                        }

                        Calendar.TimeCombo {
                            id: incidenceStartTimeCombo

                            Layout.fillWidth: true
                            timeZoneOffset: root.incidenceWrapper.startTimeZoneUTCOffsetMins
                            display: root.incidenceWrapper.incidenceStart.toLocaleTimeString(Locale.NarrowFormat)
                            dateTime: root.incidenceWrapper.incidenceStart
                            onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceStartTime(hours, minutes)
                            enabled: !allDayCheckBox.checked && incidenceStartDateCombo.enabled
                            visible: !allDayCheckBox.checked
                        }
                    }
                }
            }

            FormCard.FormHeader {
                title: incidenceForm.isTodo ? i18nc("@title:group", "Due") : i18nc("@title:group", "End")
                visible: !incidenceForm.isJournal
            }

            FormCard.FormCard {
                visible: !incidenceForm.isJournal

                FormCard.AbstractFormDelegate {
                    background: null
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.CheckBox {
                            id: incidenceEndCheckBox
                            objectName: "incidenceEndCheckBox"

                            property MerkuroComponents.KDateTime oldDate: MerkuroComponents.KDateTimeFactory.invalid()

                            checked: root.incidenceWrapper.incidenceEnd.isValid
                            onClicked: {
                                if (!checked && incidenceForm.isTodo) {
                                    oldDate = root.incidenceWrapper.incidenceEnd
                                    root.incidenceWrapper.incidenceEnd = MerkuroComponents.KDateTimeFactory.invalid()
                                } else if(incidenceForm.isTodo && oldDate.isValid) {
                                    root.incidenceWrapper.incidenceEnd = oldDate
                                } else if(incidenceForm.isTodo) {
                                    root.incidenceWrapper.setIncidenceTimeToNearestQuarterHour(false, true);
                                }
                                incidenceForm.clearAllDayForUndatedTodo();
                            }
                            visible: incidenceForm.isTodo
                        }

                        Calendar.DateCombo {
                            id: incidenceEndDateCombo

                            Layout.fillWidth: true
                            display: root.incidenceWrapper.incidenceEnd.toLocaleDateString(Locale.NarrowFormat)
                            dateTime: root.incidenceWrapper.incidenceEnd
                            onNewDateChosen: (day, month, year) => {
                                root.incidenceWrapper.setIncidenceEndDate(day, month, year)
                            }
                            enabled: incidenceEndCheckBox.checked
                        }
                        Calendar.TimeCombo {
                            id: incidenceEndTimeCombo

                            Layout.fillWidth: true
                            timeZoneOffset: root.incidenceWrapper.endTimeZoneUTCOffsetMins
                            display: root.incidenceWrapper.incidenceEnd.toLocaleTimeString(Locale.NarrowFormat)
                            dateTime: root.incidenceWrapper.incidenceEnd
                            onNewTimeChosen: (hours, minutes) => root.incidenceWrapper.setIncidenceEndTime(hours, minutes)
                            enabled: !allDayCheckBox.checked && incidenceEndDateCombo.enabled
                            visible: !allDayCheckBox.checked
                        }
                    }
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title", "Timezone")
            }

            FormCard.FormCard {
                FormCard.FormComboBoxDelegate {
                    id: timeZoneComboBox
                    text: i18n("Timezone:")

                    model: Calendar.TimeZoneListModel {
                        id: timeZonesModel
                    }
                    textRole: "displayName"
                    valueRole: "id"
                    currentIndex: model ? timeZonesModel.getTimeZoneRow(root.incidenceWrapper.timeZone) : -1
                    onActivated: root.incidenceWrapper.timeZone = currentValue
                }
            }

            FormCard.FormHeader {
                title: i18nc("@title", "Repeat")
            }

            Calendar.RecurrenceEditor {
                incidenceWrapper: root.incidenceWrapper
            }

            FormCard.FormHeader {
                title: i18nc("@title:group", "Attendees")
                trailing: QQC2.ToolButton {
                    id: attendeesButton

                    down: pressed || attendeeAddChoices.opened

                    text: i18n("Add Attendee")
                    icon.name: 'list-add-symbolic'

                    onPressed: openMenu()

                    Keys.onReturnPressed: openMenu()
                    Keys.onEnterPressed: openMenu()

                    Layout.alignment: Qt.AlignTop
                    Layout.margins: Kirigami.Units.smallSpacing

                    Accessible.role: Accessible.ButtonMenu
                    Accessible.onPressAction: openMenu()

                    QQC2.ToolTip.visible: hovered && !attendeeAddChoices.visible
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    function openMenu(): void {
			attendeeAddChoices.open()
                    }

                    QQC2.Menu {
                        id: attendeeAddChoices
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
                Component.onCompleted: autoSeparators = true

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
                                    objectName: "attendeeName" + attendeeDelegate.index
                                    text: attendeeDelegate.name
                                    onTextEdited: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
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
                                    objectName: "attendeeEmail" + attendeeDelegate.index
                                    text: attendeeDelegate.email
                                    onTextEdited: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
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
                                    objectName: "attendeeStatus" + attendeeDelegate.index
                                    currentIndex: attendeeDelegate.status // role of parent
                                    onActivated: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
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
                                    objectName: "attendeeRsvp" + attendeeDelegate.index
                                    checked: attendeeDelegate.rsvp
                                    onToggled: root.incidenceWrapper.attendeesModel.setData(root.incidenceWrapper.attendeesModel.index(attendeeDelegate.index, 0),
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
                Component.onCompleted: autoSeparators = true

                FormCard.FormPlaceholderMessageDelegate {
                    text: i18nc("@info:placeholder", "There are no reminders")
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
                        objectName: "categorySelector"
                        enabled: count > 0
                        model: Akonadi.TagManager.tagModel
                        displayText: root.incidenceWrapper.categories.length > 0 ?
                            root.incidenceWrapper.categories.join(i18nc("List separator", ", ")) :
                            Kirigami.Settings.tabletMode ? i18n("Tap to set tags…") : i18n("Click to set tags…")

                        delegate: Delegates.RoundedItemDelegate {
                            id: delegate

                            required property int index
                            required property string name

                            objectName: "categoryDelegate" + name
                            text: name

                            checkable: true
                            checked: root.incidenceWrapper.categories.includes(name)
                            highlighted: false

                            topInset: index === 0 ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 2)
                            bottomInset: index === ListView.view.count - 1 ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 2)

                            contentItem: RowLayout {
                                QQC2.CheckBox {
                                    id: checkBox
                                    objectName: "categoryCheckbox" + delegate.name
                                    activeFocusOnTab: false

                                    checked: delegate.checked
                                    onClicked: delegate.toggleCategory()
                                }

                                Delegates.DefaultContentItem {
                                    itemDelegate: delegate
                                }
                            }

                            function toggleCategory(): void {
                                root.incidenceWrapper.categories = root.incidenceWrapper.categories.includes(name)
                                    ? root.incidenceWrapper.categories.filter(tag => tag !== name)
                                    : [...root.incidenceWrapper.categories, name];
                            }

                            onClicked: toggleCategory()

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
                Component.onCompleted: autoSeparators = true

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
				Layout.fillWidth: true
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
                    objectName: "descriptionField"
                    text: root.incidenceWrapper.description
                    wrapMode: TextEdit.Wrap
                    onTextEdited: root.incidenceWrapper.description = text
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
