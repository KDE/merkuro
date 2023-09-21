// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.merkuro.calendar 1.0
import org.kde.kirigamiaddons.formcard 1.0 as FormCard

FormCard.FormCardPage {
    id: root

    title: i18n("Appearance")

    FormCard.FormHeader {
        title: i18n("General settings")
        Layout.fillWidth: true
    }

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            text: i18n("Use popup to show incidence information")
            checked: Config.useIncidenceInfoPopup
            enabled: !Config.isUseIncidenceInfoPopupImmutable && !Kirigami.Settings.isMobile
            visible: !Kirigami.Settings.isMobile
            onCheckedChanged: {
                Config.useIncidenceInfoPopup = checked;
                Config.save();
            }
        }

        FormCard.FormSwitchDelegate {
            text: i18n("Show tasks in calendar views")
            checked: Config.showTodosInCalendarViews
            enabled: !Config.isShowTodosInCalendarViewsImmutable
            onClicked: {
                Config.showTodosInCalendarViews = !Config.showTodosInCalendarViews;
                Config.save();
            }
        }

        FormCard.FormSwitchDelegate {
            text: i18n("Show sub-tasks in calendar views")
            checked: Config.showSubtodosInCalendarViews &&
                     Config.showTodosInCalendarViews
            enabled: !Config.isShowSubtodosInCalendarViewsImmutable &&
                     Config.showTodosInCalendarViews
            onCheckedChanged: {
                Config.showSubtodosInCalendarViews = checked;
                Config.save();
            }
        }
        FormCard.AbstractFormDelegate {
            background: null
            contentItem: ColumnLayout {
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
        title: i18n("Month view settings")
    }

    FormCard.FormCard {
        data: [
            QQC2.ButtonGroup {
                id: monthGridModeGroup
                exclusive: true
                onCheckedButtonChanged: {
                    Config.monthGridMode = checkedButton.value;
                    Config.save();
                }
            },
            QQC2.ButtonGroup {
                id: weekdayLabelLengthGroup
                exclusive: true
                onCheckedButtonChanged: {
                    Config.weekdayLabelLength = checkedButton.value;
                    Config.save();
                }
            },
            QQC2.ButtonGroup {
                id: weekdayLabelGroup
                exclusive: true
                onCheckedButtonChanged: {
                    Config.weekdayLabelAlignment = checkedButton.value;
                    Config.save();
                }
            }
        ]
        FormCard.FormTextDelegate {
            text: i18n("Month view mode")
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            FormCard.FormRadioDelegate {
                property int value: Config.SwipeableMonthGrid
                text: i18n("Swipeable month grid")
                enabled: !Config.isMonthGridModeImmutable
                checked: Config.monthGridMode === value
                QQC2.ButtonGroup.group: monthGridModeGroup
            }
            FormCard.FormRadioDelegate {
                property int value: Config.BasicMonthGrid
                text: i18n("Basic month grid")
                enabled: !Config.isMonthGridModeImmutable
                checked: Config.monthGridMode === value
                QQC2.ButtonGroup.group: monthGridModeGroup
            }
            FormCard.FormTextDelegate {
                description: i18n("Swipeable month grid requires higher system performance.")
                visible: Config.monthGridMode === Config.SwipeableMonthGrid
            }
        }

        FormCard.FormDelegateSeparator {}
        FormCard.FormTextDelegate {
            text: i18n("Weekday label alignment")
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            FormCard.FormRadioDelegate {
                property int value: Config.Left
                text: i18n("Left")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
                QQC2.ButtonGroup.group: weekdayLabelGroup
            }
            FormCard.FormRadioDelegate {
                property int value: Config.Center
                text: i18n("Center")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
                QQC2.ButtonGroup.group: weekdayLabelGroup
            }
            FormCard.FormRadioDelegate {
                property int value: Config.Right
                text: i18n("Right")
                enabled: !Config.isWeekdayLabelAlignmentImmutable
                checked: Config.weekdayLabelAlignment === value
                QQC2.ButtonGroup.group: weekdayLabelGroup
            }
        }


        FormCard.FormDelegateSeparator {}
        FormCard.FormTextDelegate {
            text: i18n("Weekday label length:")
        }

        FormCard.FormRadioDelegate {
            property int value: Config.Full
            text: i18n("Full name (Monday)")
            enabled: !Config.isWeekdayLabelLengthImmutable
            checked: Config.weekdayLabelLength === value
            QQC2.ButtonGroup.group: weekdayLabelLengthGroup
        }
        FormCard.FormRadioDelegate {
            property int value: Config.Abbreviated
            text: i18n("Abbreviated (Mon)")
            enabled: !Config.isWeekdayLabelLengthImmutable
            checked: Config.weekdayLabelLength === value
            QQC2.ButtonGroup.group: weekdayLabelLengthGroup
        }
        FormCard.FormRadioDelegate {
            id: configLetterDelegate
            property int value: Config.Letter
            text: i18n("Letter only (M)")
            enabled: !Config.isWeekdayLabelLengthImmutable
            checked: Config.weekdayLabelLength === value
            QQC2.ButtonGroup.group: weekdayLabelLengthGroup
        }

        FormCard.FormDelegateSeparator { above: showWeekNumbersDelegate; below: configLetterDelegate }
        FormCard.FormCheckDelegate {
            id: showWeekNumbersDelegate
            text: i18n("Show week numbers")
            checked: Config.showWeekNumbers
            enabled: !Config.isShowWeekNumbersImmutable
            onCheckedChanged: {
                Config.showWeekNumbers = checked;
                Config.save();
            }
        }
        FormCard.FormDelegateSeparator { above: showWeekNumbersDelegate }
        FormCard.AbstractFormDelegate {
            background: Item {}
            Layout.fillWidth: true
            contentItem: RowLayout {
                QQC2.Label {
                    text: i18n("Grid border width (pixels):")
                }
                QQC2.SpinBox {
                    Layout.fillWidth: true
                    value: Config.monthGridBorderWidth
                    onValueModified: {
                        Config.monthGridBorderWidth = value;
                        Config.save();
                    }
                    from: 0
                    to: 50
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: Kirigami.Units.gridUnit * 4
                    implicitHeight: height
                    height: Config.monthGridBorderWidth
                    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Week view settings")
    }

    FormCard.FormCard {
        data: QQC2.ButtonGroup {
            id: hourlyViewModeGroup
            exclusive: true
            onCheckedButtonChanged: {
                Config.hourlyViewMode = checkedButton.value;
                Config.save();
            }
        }
        FormCard.FormTextDelegate {
            text: i18n("Week view mode")
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            FormCard.FormRadioDelegate {
                property int value: Config.SwipeableInternalHourlyView
                text: i18n("Swipeable week view")
                enabled: !Config.isHourlyViewModeImmutable
                checked: Config.monthGridMode === value
                QQC2.ButtonGroup.group: hourlyViewModeGroup
            }
            FormCard.FormRadioDelegate {
                property int value: Config.BasicInternalHourlyView
                text: i18n("Basic week view")
                enabled: !Config.isHourlyViewModeImmutable
                checked: Config.monthGridMode === value
                QQC2.ButtonGroup.group: hourlyViewModeGroup
            }
            FormCard.FormTextDelegate {
                description: i18n("Swipeable week view requires higher system performance.")
                visible: Config.hourlyViewMode === Config.SwipeableInternalHourlyView
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Schedule View settings")
    }

    FormCard.FormCard {
        data: QQC2.ButtonGroup {
            id: monthListModeGroup
            exclusive: true
            onCheckedButtonChanged: {
                Config.monthListMode = checkedButton.value;
                Config.save();
            }
        }
        FormCard.FormTextDelegate {
            text: i18n("Schedule view mode")
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            FormCard.FormRadioDelegate {
                property int value: Config.SwipeableMonthList
                text: i18n("Swipeable schedule view")
                enabled: !Config.isMonthListModeImmutable
                checked: Config.monthListMode === value
                QQC2.ButtonGroup.group: monthListModeGroup
            }
            FormCard.FormRadioDelegate {
                property int value: Config.BasicMonthList
                text: i18n("Basic schedule view")
                enabled: !Config.isMonthListModeImmutable
                checked: Config.monthListMode === value
                QQC2.ButtonGroup.group: monthListModeGroup
            }
            FormCard.FormTextDelegate {
                description: i18n("Swipeable schedule view requires higher system performance.")
                visible: Config.monthListMode === Config.SwipeableMonthList
            }
        }

        FormCard.FormDelegateSeparator { above: showWeekHeaders }

        FormCard.FormCheckDelegate {
            id: showWeekHeaders
            text: i18n("Show week headers")
            checked: Config.showWeekHeaders
            enabled: !Config.isShowWeekHeadersImmutable
            onCheckedChanged: {
                Config.showWeekHeaders = checked;
                Config.save();
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Tasks View settings")
    }

    FormCard.FormCard {
        FormCard.FormCheckDelegate {
            text: i18n("Show completed sub-tasks")
            checked: Config.showCompletedSubtodos
            enabled: !Config.isShowCompletedSubtodosImmutable
            onCheckedChanged: {
                Config.showCompletedSubtodos = checked;
                Config.save();
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Maps")
    }

    FormCard.FormCard {
        FormCard.FormCheckDelegate {
            id: enableMapsDelegate
            text: i18n("Enable maps")
            checked: Config.enableMaps
            enabled: !Config.isEnableMapsImmutable
            onCheckedChanged: {
                Config.enableMaps = checked;
                Config.save();
            }
            description: i18n("May cause crashing on some systems.")
        }

        FormCard.FormDelegateSeparator { above: enableMapsDelegate }
    }

    FormCard.FormHeader {
        title: i18n("Location marker")
    }

    FormCard.FormCard {
        FormCard.FormRadioDelegate {
            property int value: Config.Circle
            text: i18n("Circle (shows area of location)")
            enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
            checked: Config.locationMarker === value
            QQC2.ButtonGroup.group: locationGroup
        }
        FormCard.FormRadioDelegate {
            property int value: Config.Pin
            text: i18n("Pin (shows exact location)")
            enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
            checked: Config.locationMarker === value
            QQC2.ButtonGroup.group: locationGroup
        }

        data: QQC2.ButtonGroup {
            id: locationGroup
            exclusive: true
            onCheckedButtonChanged: {
                Config.locationMarker = checkedButton.value;
                Config.save();
            }
        }
    }
}
