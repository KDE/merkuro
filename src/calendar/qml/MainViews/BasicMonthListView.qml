// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import org.kde.merkuro.calendar as Calendar

/**
 * This is the schedule view
 */
QQC2.ScrollView {
    id: scrollView

    required property var openOccurrence
    required property date startDate
    required property bool dragDropEnabled
    required property bool isCurrentItem

    readonly property int daysInMonth: new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0).getDate()

    property real savedYScrollPos: 0

    property real maxTimeLabelWidth: 0

    readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
    readonly property bool isDark: Calendar.CalendarUiUtils.darkMode

    contentWidth: availableWidth
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    function addIncidence(type, eventDate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.IncidenceEditorManager.openNewIncidenceEditorDialog(QQC2.ApplicationWindow.window, type, eventDate);
    }

    function viewIncidence(modelData, incidenceItem) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpView(modelData, incidenceItem);
    }

    function deleteIncidence(incidencePtr, deleteDate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpDelete(incidencePtr, deleteDate);
    }

    function completeTodo(incidencePtr) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.completeTodo(incidencePtr);
    }

    function moveIncidence(startOffset, occurrenceDate, incidenceWrapper, caughtDelegate) {
        savedYScrollPos = QQC2.ScrollBar.vertical.visualPosition;
        Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, occurrenceDate, caughtDelegate);
    }

    function moveToSelected() {
        if (savedYScrollPos > 0) {
            QQC2.ScrollBar.vertical.position = savedYScrollPos;
            return;
        }

        const currentDate = Calendar.DateTimeState.currentDate;
        if (currentDate.getDate() > 1 && currentDate.getMonth() === startDate.getMonth() && currentDate.getFullYear() === startDate.getFullYear()) {
            scheduleListView.positionViewAtIndex(currentDate.getDate() - 1, ListView.Beginning);
        } else {
            scheduleListView.positionViewAtBeginning()
        }
    }

    ListView {
        id: scheduleListView

        highlightRangeMode: ListView.ApplyRange

        onCountChanged: if(scrollView.initialMonth) scrollView.moveToSelected()
        clip: true

        model: Calendar.MultiDayIncidenceModel {
            periodLength: 1
            showTodos: Calendar.Config.showTodosInCalendarViews
            showSubTodos: Calendar.Config.showSubtodosInCalendarViews
            active: scrollView.isCurrentItem
            model: Calendar.IncidenceOccurrenceModel {
                start: scrollView.startDate
                length: scrollView.daysInMonth
                calendar: Calendar.CalendarManager.calendar
                filter: Calendar.Filter
            }
        }

        delegate: Rectangle {
            id: backgroundRectangle

            required property var incidences
            required property var periodStartDate
            required property int index

            width: scheduleListView.width
            height: index === scheduleListView.count - 1 ? dayColumn.height + Kirigami.Units.largeSpacing : dayColumn.height
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: incidenceDropArea.containsDrag ? Kirigami.Theme.positiveBackgroundColor :
                dayGrid.isToday ? Kirigami.Theme.activeBackgroundColor :
                Kirigami.Theme.backgroundColor

            Calendar.DayTapHandler {
                id: dayTapHandler
                addDate: backgroundRectangle.periodStartDate
                onDeselect: Calendar.CalendarUiUtils.appMain.incidenceInfoViewer.close()
            }

            DropArea {
                id: incidenceDropArea
                anchors.fill: parent
                z: 9999
                onDropped: drop => {
                    if(scrollView.isCurrentItem) {
                        if (Calendar.DateUtils.sameDay(dayTapHandler.addDate, drop.source.occurrenceDate)) {
                            return;
                        }
                        scrollView.savedYScrollPos = scrollView.QQC2.ScrollBar.vertical.visualPosition;

                        const pos = mapToItem(scrollView, backgroundRectangle.x, backgroundRectangle.y);
                        drop.source.caughtX = pos.x + dayGrid.dayLabelWidth + Kirigami.Units.largeSpacing;
                        drop.source.caughtY = pos.y + dayColumn.spacing + Kirigami.Units.largeSpacing;
                        drop.source.caught = true;

                        const incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
                        incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                        let sameTimeOnDate = new Date(dayTapHandler.addDate);
                        sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                        const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                        scrollView.moveIncidence(offset, drop.source.occurrenceDate, incidenceWrapper, drop.source);
                    }
                }
            }

            ColumnLayout {
                // Tip: do NOT hide an entire delegate.
                // This will very much screw up use of positionViewAtIndex.

                id: dayColumn
                // TODO: 700 is an arbitrary value. The goal is just to have it not take up the entire width of the screen.
                //       Maybe there's a better value?
                width: Math.min(parent.width, 700)
                anchors.centerIn: parent

                Kirigami.ListSectionHeader {
                    id: weekHeading

                    Layout.fillWidth: true
                    Layout.bottomMargin: -dayColumn.spacing // Remove default spacing, bring week header right down to day square

                    text: {
                        if (!weekHeading.visible)
                            return "";
                        const range = getDateRange();
                        const format = i18nc("Represents a date format. This should be adapted to locale conventions. " +
                                             "This will be used in a header, specifying the start & end day of a week. " +
                                             "The month & year are specified above this in the UI, and may be ommited.",
                                             "ddd d");
                        return i18nc(
                            "%1 & %2 are two localised short dates indicating the start & end of a week using the format"+
                                " specified earlier. %1 is the start, %2 the end.",
                            "%1–%2",
                            range.startDate.toLocaleDateString(Qt.locale(), format),
                            range.endDate.toLocaleDateString(Qt.locale(), format)
                        );
                    }
                    Accessible.name: {
                        if (!weekHeading.visible)
                            return "";
                        const range = getDateRange();
                        const format = i18nc("Represents a date format. This should be adapted to locale conventions. " +
                                             "This will be used in a header, specifying the start & end day of a week. " +
                                             "The month & year are specified above this in the UI, and may be ommited. " +
                                             "The formated date will be read aloud by screen readers.",
                                             "dddd d");
                        return i18nc(
                            "%1 & %2 are two localised dates indicating the start & end of a week using the format specified above." +
                                " %1 is the start, %2 the end. This string is intended to be read by a screen reader.",
                            "From %1 to %2",
                            range.startDate.toLocaleDateString(Qt.locale(), format),
                            range.endDate.toLocaleDateString(Qt.locale(), format)
                        );
                    }
                    visible: Calendar.Config.showWeekHeaders &&
                        backgroundRectangle.periodStartDate !== undefined &&
                        (backgroundRectangle.periodStartDate.getDay() === Qt.locale().firstDayOfWeek ||
                         backgroundRectangle.index === 0)

                    // This function computes the date range for this
                    // section, to be shown as a header. It is usually
                    // 7 days, but may be less than that for the first
                    // section (as the month may start in the middle
                    // of a week), and the last one, for similar
                    // reasons.
                    function getDateRange() {
                        // Get the Day Of Week that corresponds to the first day in a week for the current locale.
                        const LOCALE_START_DOW = Qt.locale().firstDayOfWeek;
                        const LOCALE_END_DOW = LOCALE_START_DOW === 1 ? 7 : LOCALE_START_DOW - 1

                        const currentDOW = backgroundRectangle.periodStartDate.getDay()
                        const startDate = backgroundRectangle.periodStartDate;

                        // If the current DOW is the start DOW, the calculation to get to the end of the week are quite simple!
                        if (currentDOW === LOCALE_START_DOW) {
                            // Let's add 6 days to the start date, while making sure not to overflow the current month
                            let endDate = new Date(startDate);
                            endDate.setDate(Math.min(endDate.getDate() + 6, scrollView.daysInMonth));
                            // This will give us a date fairly easily!
                            return { startDate, endDate };
                        }

                        // Now, if our start date is not alligned with the start of the week, we have to do some math
                        // to figure out how many days we need to skip to get to the end of the week.
                        // In case the current DOW is past the end of week DOW for the current locale (i.e. we're on a
                        // Sunday and the week ends on Fridays), we need to shift the end of week DOW by 7 days (i.e.
                        // going over to the next week) to calculate the number of days to skip.
                        // Otherwise, we can just get the number of day to skip by substraction.
                        let distanceToEndDOW = (currentDOW > LOCALE_END_DOW) ?
                            LOCALE_END_DOW + 7 - currentDOW :
                            LOCALE_END_DOW - currentDOW;

                        // Then, let's just find the end date by adding the number of days to skip to the current date
                        let endDate = new Date(startDate);
                        endDate.setDate(endDate.getDate() + distanceToEndDOW);

                        return { startDate, endDate };
                    }
                }

                Kirigami.Separator {
                    id: topSeparator
                    Layout.fillWidth: true
                    z: 1
                }

                // Day + incidences
                GridLayout {
                    id: dayGrid

                    columns: 2
                    rows: 2
                    visible: incidences.length > 0 || !Calendar.Config.hideEmptyDays

                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing

                    property real dayLabelWidth: Kirigami.Units.gridUnit * 4
                    property bool isToday: new Date(backgroundRectangle.periodStartDate).setHours(0,0,0,0) === new Date().setHours(0,0,0,0)

                    QQC2.Button {
                        id: dayButton
                        Layout.fillHeight: true

                        padding: Kirigami.Units.smallSpacing
                        rightPadding: Kirigami.Units.largeSpacing

                        Layout.preferredWidth: metrics.width

                        flat: true
                        onClicked: Calendar.CalendarUiUtils.openDayLayer(backgroundRectangle.periodStartDate)

                        // The goal is to measure how long a string of ~4 characters, in the current default font,
                        // using the maximum font size a dayButton label can be, is.
                        // This is used to size the dayButton accordingly, to make sure all buttons have the same
                        // size, regardless of their actual content.
                        // Note: There is possibly a smarter way to do this in QML!
                        property TextMetrics metrics: TextMetrics {
                            font.family: Kirigami.Theme.defaultFont.family
                            // Level 3 Kirigami.Heading uses Kirigami.Theme.defaultFont.pointSize * 1.15 font size.
                            // Note: maybe this could be done in a different, smarter way?
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
                            elide: Text.ElideNone
                            text: "WWWW"
                        }

                        property Item smallDayLabel: QQC2.Label {
                            id: smallDayLabel

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            Layout.fillWidth: true

                            visible: !cardsColumn.visible
                            wrapMode: Text.Wrap
                            textFormat: Text.StyledText
                            color: Kirigami.Theme.disabledTextColor
                            text: backgroundRectangle.periodStartDate.toLocaleDateString(Qt.locale(), "ddd <b>dd</b>")
                        }


                        property Item largeDayLabel: Kirigami.Heading {
                            id: largeDayLabel

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignTop
                            Layout.fillWidth: true

                            level: dayGrid.isToday ? 1 : 3
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            color: dayGrid.isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            text: backgroundRectangle.periodStartDate.toLocaleDateString(Qt.locale(), "ddd<br><b>dd</b>")
                        }


                        contentItem: (backgroundRectangle.incidences.length > 0 || dayGrid.isToday) ? largeDayLabel : smallDayLabel
                    }

                    QQC2.Label {
                        id: emptyDayText

                        Layout.alignment: Qt.AlignVCenter
                        visible: !cardsColumn.visible
                        text: i18nc("Date has no events or tasks set", "Clear day.")
                        color: Kirigami.Theme.disabledTextColor
                    }

                    ColumnLayout {
                        id: cardsColumn

                        Layout.fillWidth: true
                        visible: backgroundRectangle.incidences.length || dayGrid.isToday

                        Kirigami.AbstractCard {
                            id: suggestCard

                            Layout.fillWidth: true

                            showClickFeedback: true
                            visible: !backgroundRectangle.incidences.length && dayGrid.isToday

                            contentItem: QQC2.Label {
                                property string selectMethod: Kirigami.Settings.isMobile ? i18n("Tap") : i18n("Click")
                                text: i18n("Nothing on the books today. %1 to add something.", selectMethod)
                                wrapMode: Text.Wrap
                            }

                            onClicked: scrollView.addIncidence(Calendar.IncidenceWrapper.TypeEvent, backgroundRectangle.periodStartDate)
                        }

                        Repeater {
                            model: backgroundRectangle.incidences
                            delegate: Repeater {
                                id: incidencesRepeater

                                required property var modelData

                                model: modelData

                                delegate: Calendar.MonthListViewIncidenceDelegate {
                                    required property var modelData
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
