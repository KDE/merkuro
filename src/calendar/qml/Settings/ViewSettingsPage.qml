// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.calendar

FormCard.FormCardPage {
    title: i18n("Calendar Views")

    FormCard.FormHeader {
        title: i18n("Holidays")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: showHolidays
            objectName: "showHolidaysSwitch"
            text: i18n("Show holidays in calendar views")
            checked: Config.showHolidaysInCalendarViews
            enabled: !Config.isShowHolidaysInCalendarViewsImmutable
            onToggled: {
                Config.showHolidaysInCalendarViews = showHolidays.checked;
                Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: holidayRegions
            objectName: "holidayRegionsCombo"
            text: i18nc("@label:listbox", "Holiday regions")
            enabled: !Config.isShowHolidaysInCalendarViewsImmutable && Config.showHolidaysInCalendarViews
            model: HolidayRegionModel {
                id: holidayRegionModel
            }
            currentIndex: Config.holidayRegions.length === 0 ? 0 : -1
            displayText: if (Config.holidayRegions.length === 0) {
                return holidayRegions.currentText;
            } else {
                return Config.holidayRegions.map((regionCode) => holidayRegionModel.regionLanguage(regionCode)).join(', ')
            }
            textRole: 'displayName'
            comboBoxDelegate: Delegates.RoundedItemDelegate {
                id: delegate

                required property string displayName
                required property string regionCode
                required property int index

                text: displayName

                checkable: true
                checked: Config.holidayRegions.includes(regionCode) || (Config.holidayRegions.length === 0 && regionCode.length === 0)
                onToggled: if (checked) {
                    const regions = Config.holidayRegions;
                    regions.push(regionCode);
                    Config.holidayRegions = regions;
                    Config.save();
                } else {
                    const regions = Config.holidayRegions;
                    const index = regions.indexOf(regionCode);
                    if (index !== -1) {
                        regions.splice(index, 1);
                        Config.holidayRegions = regions;
                        Config.save();
                    }
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.mediumSpacing

                    QQC2.CheckBox {
                        id: checkBoxItem
                        focusPolicy: Qt.NoFocus // provided by delegate

                        topPadding: 0
                        leftPadding: 0
                        rightPadding: 0
                        bottomPadding: 0

                        onToggled: {
                            delegate.toggle();
                            delegate.toggled();
                        }
                        onClicked: delegate.clicked()
                        onPressAndHold: delegate.pressAndHold()
                        onDoubleClicked: delegate.doubleClicked()

                        contentItem: null // Remove right margin
                        spacing: 0

                        enabled: delegate.enabled
                        checked: delegate.checked

                        Accessible.ignored: true
                    }

                    QQC2.Label {
                        text: delegate.text
                        elide: Text.ElideRight
                        Accessible.ignored: true
                        Layout.fillWidth: true
                    }
                }
            }
        }

    }

    FormCard.FormHeader {
        title: i18n("Event Details")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormComboBoxDelegate {
            id: eventDetails
            objectName: "eventDetailsCombo"
            text: i18n("Open event details in")
            visible: !Kirigami.Settings.isMobile
            enabled: !Config.isUseIncidenceInfoPopupImmutable
            model: [i18n("Popup"), i18n("Side panel")]
            currentIndex: Config.useIncidenceInfoPopup ? 0 : 1
            onActivated: function(index: int): void {
                Config.useIncidenceInfoPopup = index === 0;
                Config.save();
            }
        }

        FormCard.AbstractFormDelegate {
            background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: i18n("Past event transparency")
                    Layout.fillWidth: true
                }
                QQC2.Slider {
                    Layout.fillWidth: true
                    stepSize: 0.05
                    from: 0
                    to: 1
                    value: Config.pastEventsTransparencyLevel
                    onMoved: {
                        Config.pastEventsTransparencyLevel = value;
                        Config.save();
                    }
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Month View")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: showWeekNumbers
            text: i18n("Show week numbers")
            checked: Config.showWeekNumbers
            enabled: !Config.isShowWeekNumbersImmutable
            onToggled: {
                Config.showWeekNumbers = showWeekNumbers.checked;
                Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: weekdayAlignment
            objectName: "weekdayAlignmentCombo"
            text: i18n("Weekday label alignment")
            enabled: !Config.isWeekdayLabelAlignmentImmutable
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Left"), value: Config.Left },
                { text: i18n("Center"), value: Config.Center },
                { text: i18n("Right"), value: Config.Right }
            ]
            currentIndex: Config.weekdayLabelAlignment
            onActivated: function(index: int): void {
                Config.weekdayLabelAlignment = weekdayAlignment.currentValue;
                Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: weekdayLength
            objectName: "weekdayLengthCombo"
            text: i18n("Weekday label length")
            enabled: !Config.isWeekdayLabelLengthImmutable
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Full name (Monday)"), value: Config.Full },
                { text: i18n("Abbreviated (Mon)"), value: Config.Abbreviated },
                { text: i18n("Letter only (M)"), value: Config.Letter }
            ]
            currentIndex: Config.weekdayLabelLength
            onActivated: function(index: int): void {
                Config.weekdayLabelLength = weekdayLength.currentValue;
                Config.save();
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Schedule View")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: showWeekHeaders
            text: i18n("Show week headers")
            checked: Config.showWeekHeaders
            enabled: !Config.isShowWeekHeadersImmutable
            onToggled: {
                Config.showWeekHeaders = showWeekHeaders.checked;
                Config.save();
            }
        }

        FormCard.FormSwitchDelegate {
            id: hideEmptyDays
            text: i18n("Hide empty days")
            checked: Config.hideEmptyDays
            enabled: !Config.isHideEmptyDaysImmutable
            onToggled: {
                Config.hideEmptyDays = hideEmptyDays.checked;
                Config.save();
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Advanced Presentation")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormComboBoxDelegate {
            id: monthViewMode
            objectName: "monthViewModeCombo"
            text: i18n("Month view")
            enabled: !Config.isMonthGridModeImmutable
            description: Config.monthGridMode === Config.SwipeableMonthGrid ? i18n("Swipeable views require higher system performance.") : ""
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Swipeable"), value: Config.SwipeableMonthGrid },
                { text: i18n("Basic"), value: Config.BasicMonthGrid }
            ]
            currentIndex: Config.monthGridMode === Config.SwipeableMonthGrid ? 0 : 1
            onActivated: function(index: int): void {
                Config.monthGridMode = monthViewMode.currentValue;
                Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: weekViewMode
            objectName: "weekViewModeCombo"
            text: i18n("Week view")
            enabled: !Config.isHourlyViewModeImmutable
            description: Config.hourlyViewMode === Config.SwipeableInternalHourlyView ? i18n("Swipeable views require higher system performance.") : ""
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Swipeable"), value: Config.SwipeableInternalHourlyView },
                { text: i18n("Basic"), value: Config.BasicInternalHourlyView }
            ]
            currentIndex: Config.hourlyViewMode === Config.SwipeableInternalHourlyView ? 0 : 1
            onActivated: function(index: int): void {
                Config.hourlyViewMode = weekViewMode.currentValue;
                Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: scheduleViewMode
            objectName: "scheduleViewModeCombo"
            text: i18n("Schedule view")
            enabled: !Config.isMonthListModeImmutable
            description: Config.monthListMode === Config.SwipeableMonthList ? i18n("Swipeable views require higher system performance.") : ""
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Swipeable"), value: Config.SwipeableMonthList },
                { text: i18n("Basic"), value: Config.BasicMonthList }
            ]
            currentIndex: Config.monthListMode === Config.SwipeableMonthList ? 0 : 1
            onActivated: function(index: int): void {
                Config.monthListMode = scheduleViewMode.currentValue;
                Config.save();
            }
        }

        FormCard.FormSpinBoxDelegate {
            id: gridBorderWidth
            label: i18n("Month grid border width (pixels)")
            enabled: !Config.isMonthGridBorderWidthImmutable
            from: 0
            to: 50
            value: Config.monthGridBorderWidth
            onValueModified: {
                Config.monthGridBorderWidth = gridBorderWidth.value;
                Config.save();
            }
        }
    }
}
