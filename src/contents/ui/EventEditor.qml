// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0

Kirigami.OverlaySheet {
	id: eventEditorSheet

	property bool validDates: eventStartDateCombo.validDate && (eventEndDateCombo.validDate || allDayCheckBox.checked)

	header: Kirigami.Heading {
        text: "Event"
    }

    footer: QQC2.DialogButtonBox {
		standardButtons: QQC2.DialogButtonBox.Cancel

		QQC2.Button {
			text: "Add"
			enabled: titleField.text && eventEditorSheet.validDates // Also needs to check for selected calendar and date
			QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
		}

        onRejected: eventEditorSheet.close()
    }

    ColumnLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true

		Kirigami.InlineMessage {
			id: invalidDateMessage
			Layout.fillWidth: true
			visible: !eventEditorSheet.validDates
			type: Kirigami.MessageType.Error
			text: "Invalid dates provided."
		}

		Kirigami.FormLayout {
			id: eventForm
			property date todayDate: new Date()

			QQC2.ComboBox {
				id: calendarCombo
				Kirigami.FormData.label: "Calendar:"
				Layout.fillWidth: true
				model: CalendarManager.collections
				delegate: Kirigami.BasicListItem {
					leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
					label: display
					icon: decoration
					onClicked: calendarCombo.displayText = display
				}
				popup.z: 1000
			}
			QQC2.TextField {
				id: titleField
				Kirigami.FormData.label: "<b>Title</b>:"
				placeholderText: "Required"
			}
			QQC2.TextField {
				id: locationField
				Kirigami.FormData.label: "Location:"
			}

			Kirigami.Separator {
				Kirigami.FormData.isSection: true
			}

			QQC2.CheckBox {
				id: allDayCheckBox
				Kirigami.FormData.label: "All day event:"
			}
			RowLayout {
				Kirigami.FormData.label: "Start:"
				Layout.fillWidth: true

				QQC2.ComboBox {
					id: eventStartDateCombo
					Layout.fillWidth: true
					editable: true
					editText: eventStartDatePicker.clickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);

					inputMethodHints: Qt.ImhDate

					property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
					property bool validDate: !isNaN(dateFromText.getTime())

					onDateFromTextChanged: {
						var datePicker = eventStartDatePicker
						if (validDate && activeFocus) {
							datePicker.selectedDate = dateFromText
							datePicker.clickedDate = dateFromText
						}
					}

					popup: QQC2.Popup {
						id: eventStartDatePopup
						width: parent.width*2
						height: Kirigami.Units.gridUnit * 18
						z: 1000

						DatePicker {
							id: eventStartDatePicker
							anchors.fill: parent
							onDatePicked: eventStartDatePopup.close()
						}
					}
				}
				QQC2.ComboBox {
					id: eventStartTimeCombo
					Layout.fillWidth: true
					property string displayHour: eventStartTimePicker.hours < 10 ?
						String(eventStartTimePicker.hours).padStart(2, "0") : eventStartTimePicker.hours
					property string displayMinutes: eventStartTimePicker.minutes < 10 ?
						String(eventStartTimePicker.minutes).padStart(2, "0") : eventStartTimePicker.minutes

					editable: true
					editText: displayHour + ":" + displayMinutes
					enabled: !allDayCheckBox.checked
					visible: !allDayCheckBox.checked

					inputMethodHints: Qt.ImhTime
					validator: RegularExpressionValidator {
						regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
					}

					onEditTextChanged: {
						var timePicker = eventStartTimePicker
						if (acceptableInput && activeFocus) { // Need to check for activeFocus or on load the text gets reset to 00:00
							timePicker.setToTimeFromString(editText);
						}
					}
					popup: QQC2.Popup {
						id: eventStartTimePopup
						width: parent.width
						height: parent.width
						z: 1000

						TimePicker {
							id: eventStartTimePicker
							onDone: eventStartTimePopup.close()
						}
					}
				}
			}
			RowLayout {
				Kirigami.FormData.label: "End:"
				Layout.fillWidth: true
				visible: !allDayCheckBox.checked

				QQC2.ComboBox {
					id: eventEndDateCombo
					Layout.fillWidth: true
					editable: true
					editText: eventEndDatePicker.clickedDate.toLocaleDateString(Qt.locale(), Locale.NarrowFormat);
					enabled: !allDayCheckBox.checked

					property date dateFromText: Date.fromLocaleDateString(Qt.locale(), editText, Locale.NarrowFormat)
					property bool validDate: !isNaN(dateFromText.getTime())

					onDateFromTextChanged: {
						var datePicker = eventEndDatePicker
						if (validDate && activeFocus) {
							datePicker.selectedDate = dateFromText
							datePicker.clickedDate = dateFromText
						}
					}

					popup: QQC2.Popup {
						id: eventEndDatePopup
						width: parent.width*2
						height: Kirigami.Units.gridUnit * 18
						z: 1000

						DatePicker {
							id: eventEndDatePicker
							anchors.fill: parent
							onDatePicked: eventEndDatePopup.close()
						}
					}
				}
				QQC2.ComboBox {
					id: eventEndTimeCombo
					Layout.fillWidth: true
					property string displayHour: eventEndTimePicker.hours < 10 ?
						String(eventEndTimePicker.hours).padStart(2, "0") : eventEndTimePicker.hours
					property string displayMinutes: eventEndTimePicker.minutes < 10 ?
						String(eventEndTimePicker.minutes).padStart(2, "0") : eventEndTimePicker.minutes

					editable: true
					editText: displayHour + ":" + displayMinutes
					enabled: !allDayCheckBox.checked

					inputMethodHints: Qt.ImhTime
					validator: RegularExpressionValidator {
						regularExpression: /^([0-1]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$/
					}

					onEditTextChanged: {
						var timePicker = eventEndTimePicker
						if (acceptableInput && activeFocus) {
							timePicker.setToTimeFromString(editText);
						}
					}

					popup: QQC2.Popup {
						id: eventEndTimePopup
						width: parent.width
						height: parent.width
						z: 1000

						TimePicker {
							id: eventEndTimePicker
							onDone: eventEndTimePopup.close()
						}
					}
				}
			}
			QQC2.ComboBox {
				id: repeatComboBox
				Kirigami.FormData.label: "Repeat:"
				Layout.fillWidth: true
				model: ["Never", "Daily", "Weekly", "Monthly", "Yearly"]
				delegate: Kirigami.BasicListItem {
					label: modelData
				}
				popup.z: 1000
			}

			Kirigami.Separator {
				Kirigami.FormData.isSection: true
			}

			QQC2.TextArea {
				id: descriptionTextArea
				Kirigami.FormData.label: "Description:"
				placeholderText: "Add a description..."
				Layout.fillWidth: true
			}
			QQC2.ComboBox {
				id: remindersComboBox
				Kirigami.FormData.label: "Reminder:"
				Layout.fillWidth: true
			}
			QQC2.Button {
				id: attendeesButton
				Kirigami.FormData.label: "Attendees:"
				text: "Add attendees"
				Layout.fillWidth: true
			}
		}
	}
}
