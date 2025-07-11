// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

import org.kde.merkuro.calendar as Calendar

Column {
    id: viewColumn

    required property var openOccurrence
    required property int daysToShow
    required property date startDate

    property date endDate: Calendar.Utils.addDaysToDate(startDate, viewColumn.daysToShow)

    readonly property date currentDate: Calendar.DateTimeState.currentDate
    readonly property int daysFromWeekStart: Calendar.DateUtils.fullDaysBetweenDates(startDate, currentDate) - 1

    readonly property int minutesFromStartOfDay: (currentDate.getHours() * 60) + currentDate.getMinutes()
    readonly property bool isDark: Calendar.CalendarUiUtils.darkMode
    property bool dragDropEnabled: true

    property int allDayViewDelegateHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing

    property int periodLength: 15
    property real scrollbarWidth: 0
    readonly property real dayWidth: ((width - hourLabelWidth - leftPadding - scrollbarWidth) / daysToShow) - gridLineWidth
    readonly property real incidenceSpacing: Kirigami.Units.smallSpacing / 2
    readonly property real gridLineWidth: 1.0
    readonly property real hourLabelWidth: hourLabelMetrics.boundingRect(new Date(0,0,0,0,0,0,0).toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)).width +
        Kirigami.Units.largeSpacing * 2.5
    readonly property real periodHeight: Kirigami.Units.gridUnit

    property int multiDayLinesShown: 0
    property bool isCurrentItem: true

    property real scrollPosition: 0

    readonly property alias hourScrollView: hourlyView
    readonly property var hourLabels: Calendar.Utils.hourlyViewLocalisedHourLabels

    spacing: 0

    Connections {
        target: Calendar.DateTimeState
        function onSelectedDateChanged() {
            hourScrollView.setToCurrentTime();
        }
    }

    Component.onCompleted: {
        if (Calendar.Config.showHolidaysInCalendarViews) {
            Calendar.HolidayModel.loadDateRange(startDate, daysToShow)
            holidayRow.checkHolidays()
        }
        hourScrollView.setToCurrentTime();
    }

    Connections {
        target: Calendar.Config
        function onShowHolidaysInCalendarViewsChanged(): void {
            if (Calendar.Config.showHolidaysInCalendarViews) {
                Calendar.HolidayModel.loadDateRange(viewColumn.startDate, viewColumn.daysToShow)
                holidayRow.checkHolidays()
            }
        }
    }

    FontMetrics {
        id: hourLabelMetrics
        font.bold: true
    }

    FontMetrics {
        id: fontMetrics
    }

    Row {
        id: headingRow
        width: viewColumn.width
        spacing: viewColumn.gridLineWidth

        Kirigami.Heading {
            id: weekNumberHeading

            width: viewColumn.hourLabelWidth - viewColumn.gridLineWidth
            horizontalAlignment: Text.AlignRight
            padding: Kirigami.Units.smallSpacing
            level: 2
            text: Calendar.Utils.weekNumber(viewColumn.startDate)
            color: Kirigami.Theme.disabledTextColor
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
            }
        }

        Repeater {
            id: dayHeadings

            model: viewColumn.daysToShow
            delegate: Rectangle {
                id: dayDelegate

                required property int index

                readonly property date headingDate: Calendar.Utils.addDaysToDate(viewColumn.startDate, index)
                readonly property bool isToday: Calendar.DateTimeState.isToday(headingDate)

                width: viewColumn.dayWidth
                implicitHeight: dayHeading.implicitHeight
                color: Kirigami.Theme.backgroundColor

                Kirigami.Heading { // Heading is out of the button so the color isn't disabled when the button is
                    id: dayHeading

                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    padding: Kirigami.Units.smallSpacing
                    level: 2
                    color: isToday ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    text: {
                        const longText = dayDelegate.headingDate.toLocaleDateString(Qt.locale(), "dddd <b>d</b>");
                        const mediumText = dayDelegate.headingDate.toLocaleDateString(Qt.locale(), "ddd <b>d</b>");
                        const shortText = mediumText.slice(0,1) + " " + dayDelegate.headingDate.toLocaleDateString(Qt.locale(), "<b>d</b>");


                        if (fontMetrics.boundingRect(longText).width < width) {
                            return longText;
                        } else if(fontMetrics.boundingRect(mediumText).width < width) {
                            return mediumText;
                        } else {
                            return shortText;
                        }
                    }
                }

                QQC2.Button {
                    implicitHeight: dayHeading.implicitHeight
                    width: parent.width
                    activeFocusOnTab: viewColumn.isCurrentItem

                    flat: true
                    enabled: viewColumn.daysToShow === 7
                    Accessible.name: dayHeading.text.replace(/<\/?b>/g, '')
                    onClicked: {
                        Calendar.DateTimeState.selectedDate = dayDelegate.headingDate;
                        applicationWindow().pageStack.layers.push("qrc:/HourlyView.qml", {
                            daysToShow: 1,
                        });
                    }
                }
            }
        }
        Rectangle { // Cover up the shadow of headerTopSeparator above the scrollbar
            color: Kirigami.Theme.backgroundColor
            height: parent.height
            width: viewColumn.scrollbarWidth
        }
    }

    WeekViewHolidayRow {
        id: holidayRow
        startDate: viewColumn.startDate
        daysToShow: viewColumn.daysToShow
        dayWidth: viewColumn.dayWidth
        hourLabelWidth: viewColumn.hourLabelWidth
        scrollbarWidth: viewColumn.scrollbarWidth
        showHolidaysConfig: Calendar.Config.showHolidaysInCalendarViews
    }

    Kirigami.Separator {
        id: headerTopSeparator
        width: viewColumn.width
        height: viewColumn.gridLineWidth
        z: -1

        RectangularGlow {
            anchors.fill: parent
            z: -1
            glowRadius: 5
            spread: 0.3
            color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
            visible: !allDayViewLoader.active
        }
    }

    Item {
        id: allDayHeader
        width: viewColumn.width
        height: actualHeight
        visible: allDayViewLoader.active

        readonly property int minHeight: Kirigami.Units.gridUnit *2
        readonly property int maxHeight: viewColumn.height / 3
        readonly property int lineHeight: viewColumn.multiDayLinesShown > 0 ?
            viewColumn.multiDayLinesShown * (viewColumn.allDayViewDelegateHeight + viewColumn.incidenceSpacing) + Kirigami.Units.smallSpacing :
            0
        readonly property int defaultHeight: Math.min(lineHeight, maxHeight)
        property int actualHeight: {
            if (Calendar.Config.weekViewAllDayHeaderHeight === -1) {
                return defaultHeight;
            } else {
                return Calendar.Config.weekViewAllDayHeaderHeight;
            }
        }

        NumberAnimation {
            id: resetAnimation
            target: allDayHeader
            property: "height"
            to: allDayHeader.defaultHeight
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            onFinished: {
                Calendar.Config.weekViewAllDayHeaderHeight = -1;
                Calendar.Config.save();
                allDayHeader.actualHeight = allDayHeader.defaultHeight;
            }
        }

        Rectangle {
            id: headerBackground
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
        }

        Kirigami.ShadowedRectangle {
            anchors.left: parent.left
            anchors.top: parent.bottom
            width: viewColumn.hourLabelWidth
            height: Calendar.Config.weekViewAllDayHeaderHeight !== -1 ?
                resetHeaderHeightButton.height :
                0
            visible: height !== 0
            z: -1
            corners.bottomRightRadius: Kirigami.Units.smallSpacing
            shadow.size: Kirigami.Units.largeSpacing
            shadow.color: Qt.rgba(0.0, 0.0, 0.0, 0.2)
            shadow.yOffset: 2
            shadow.xOffset: 2
            color: Kirigami.Theme.backgroundColor
            border.width: viewColumn.gridLineWidth
            border.color: headerBottomSeparator.color

            Behavior on height { NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            } }

            Item {
                width: viewColumn.hourLabelWidth
                height: parent.height
                clip: true

                QQC2.ToolButton {
                    id: resetHeaderHeightButton
                    width: viewColumn.hourLabelWidth
                    text: i18nc("@action:button", "Reset")
                    onClicked: resetAnimation.start()
                }
            }
        }

        QQC2.Label {
            width: viewColumn.hourLabelWidth
            height: parent.height
            padding: Kirigami.Units.smallSpacing
            leftPadding: Kirigami.Units.largeSpacing
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignRight
            text: i18n("All day or Multi day")
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
        }

        Loader {
            id: allDayViewLoader
            anchors.fill: parent
            anchors.leftMargin: viewColumn.hourLabelWidth
            asynchronous: !viewColumn.isCurrentItem

            sourceComponent: Item {
                id: allDayViewItem
                implicitHeight: allDayHeader.actualHeight
                clip: true

                Repeater {
                    model: Calendar.MultiDayIncidenceModel {
                        periodLength: viewColumn.daysToShow
                        filters: Calendar.MultiDayIncidenceModel.AllDayOnly | Calendar.MultiDayIncidenceModel.MultiDayOnly
                        showTodos: Calendar.Config.showTodosInCalendarViews
                        showSubTodos: Calendar.Config.showSubtodosInCalendarViews
                        active: viewColumn.isCurrentItem
                        model: Calendar.IncidenceOccurrenceModel {
                            start: viewColumn.startDate
                            length: viewColumn.daysToShow
                            calendar: Calendar.CalendarManager.calendar
                            filter: Calendar.Filter
                        }
                    }

                    Layout.topMargin: Kirigami.Units.largeSpacing

                    // One row => one week
                    Item {
                        id: weekDelegate

                        required property int index
                        required property var incidences
                        required property var periodStartDate

                        width: parent.width
                        implicitHeight: allDayHeader.actualHeight
                        clip: true

                        RowLayout {
                            width: parent.width
                            height: parent.height
                            spacing: viewColumn.gridLineWidth

                            Item {
                                readonly property date startDate: weekDelegate.periodStartDate

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                QQC2.ScrollView {
                                    id: linesListViewScrollView

                                    anchors.fill: parent

                                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                                    ListView {
                                        id: linesRepeater
                                        Layout.fillWidth: true
                                        Layout.rightMargin: spacing

                                        clip: true
                                        spacing: viewColumn.incidenceSpacing

                                        model: weekDelegate.incidences
                                        onCountChanged: viewColumn.multiDayLinesShown = count
                                        delegate: Item {
                                            id: line

                                            required property var modelData

                                            height: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                                            width: ListView.view.width

                                            // Incidences
                                            Repeater {
                                                id: allDayIncidencesRepeater

                                                model: line.modelData

                                                delegate: Calendar.DayGridViewIncidenceDelegate {
                                                    id: incidenceDelegate

                                                    required property var modelData

                                                    starts: modelData.starts
                                                    duration: modelData.duration
                                                    incidenceId: modelData.incidenceId
                                                    occurrenceDate: modelData.startTime
                                                    occurrenceEndDate: modelData.endTime
                                                    incidencePtr: modelData.incidencePtr
                                                    allDay: modelData.allDay

                                                    dayWidth: viewColumn.dayWidth
                                                    height: viewColumn.allDayViewDelegateHeight
                                                    parentViewSpacing: viewColumn.gridLineWidth
                                                    horizontalSpacing: linesRepeater.spacing
                                                    openOccurrenceId: viewColumn.openOccurrence ? viewColumn.openOccurrence.incidenceId : ""
                                                    isDark: viewColumn.isDark
                                                    reactToCurrentMonth: false
                                                    dragDropEnabled: viewColumn.dragDropEnabled
                                                }
                                            }
                                        }

                                        ListView {
                                            id: allDayIncidencesBackgroundView
                                            anchors.fill: parent
                                            spacing: viewColumn.gridLineWidth
                                            orientation: Qt.Horizontal
                                            z: -1

                                            Kirigami.Separator {
                                                anchors.fill: parent
                                                anchors.rightMargin: viewColumn.scrollbarWidth
                                                z: -1
                                            }

                                            model: viewColumn.daysToShow
                                            delegate: Rectangle {
                                                id: multiDayViewBackground

                                                required property int index

                                                readonly property date date: Calendar.Utils.addDaysToDate(viewColumn.startDate, index)
                                                readonly property bool isToday: Calendar.DateTimeState.isToday(date)
                                                readonly property string formatedDate: Qt.formatDate(date, 'yyyy-MM-dd')
                                                readonly property bool isHoliday: formatedDate in Calendar.HolidayModel.holidays
                                                readonly property color bgColor: {
                                                    if (Calendar.Config.showHolidaysInCalendarViews && isHoliday) {
                                                        return Kirigami.Theme.negativeBackgroundColor
                                                    } else if (multiDayViewIncidenceDropArea.containsDrag) {
                                                        return Kirigami.Theme.positiveBackgroundColor
                                                    } else if (isToday) {
                                                        return Kirigami.Theme.activeBackgroundColor
                                                    }
                                                    return Kirigami.Theme.backgroundColor
                                                }

                                                width: viewColumn.dayWidth
                                                height: linesListViewScrollView.height
                                                color: multiDayViewBackground.bgColor

                                                Calendar.DayTapHandler {
                                                    id: listViewMenu

                                                    addDate: parent.date
                                                    onDeselect: applicationWindow().incidenceInfoViewer.close()
                                                }

                                                DropArea {
                                                    id: multiDayViewIncidenceDropArea
                                                    anchors.fill: parent
                                                    z: 9999
                                                    onDropped: (drop) => {
                                                        if (!viewColumn.isCurrentItem) {
                                                            return;
                                                        }

                                                        const pos = mapToItem(viewColumn, x, y);
                                                        drop.source.caughtX = pos.x + viewColumn.incidenceSpacing;
                                                        drop.source.caughtY = pos.y;
                                                        drop.source.caught = true;

                                                        const incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
                                                        incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                        let sameTimeOnDate = new Date(listViewMenu.addDate);
                                                        sameTimeOnDate = new Date(sameTimeOnDate.setHours(drop.source.occurrenceDate.getHours(), drop.source.occurrenceDate.getMinutes()));
                                                        const offset = sameTimeOnDate.getTime() - drop.source.occurrenceDate.getTime();
                                                        /* There are 2 possibilities here: we move multiday incidence between days or we move hourly incidence
                                                         * to convert it into multiday incidence
                                                         */
                                                        if (drop.source.objectName === 'hourlyIncidenceDelegateBackgroundBackground') {
                                                            // This is conversion from non-multiday to multiday
                                                            Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source, true)
                                                        } else {
                                                            Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, offset, offset, drop.source.occurrenceDate, drop.source)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Calendar.ResizerSeparator {
        id: headerBottomSeparator
        width: viewColumn.width
        height: viewColumn.gridLineWidth
        oversizeMouseAreaVertical: 5
        z: Infinity
        visible: allDayViewLoader.active

        function setPos() {
            Calendar.Config.weekViewAllDayHeaderHeight = allDayHeader.actualHeight;
            Calendar.Config.save();
        }

        onDragBegin:  setPos()
        onDragReleased: setPos()
        onDragPositionChanged: (changeX, changeY) => allDayHeader.actualHeight = Math.min(allDayHeader.maxHeight, Math.max(allDayHeader.minHeight, Calendar.Config.weekViewAllDayHeaderHeight + changeY))
    }

    RectangularGlow {
        id: headerBottomShadow
        anchors.top: headerBottomSeparator.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        z: -1
        glowRadius: 5
        spread: 0.3
        color: Qt.rgba(0.0, 0.0, 0.0, 0.15)
    }

    QQC2.ScrollView {
        id: hourlyView
        width: viewColumn.width
        height: actualHeight
        contentWidth: availableWidth
        z: -2
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        readonly property real periodsPerHour: 60 / viewColumn.periodLength
        readonly property real daySections: (60 * 24) / viewColumn.periodLength
        readonly property real dayHeight: (daySections * viewColumn.periodHeight) + (viewColumn.gridLineWidth * 23)
        readonly property real hourHeight: periodsPerHour * viewColumn.periodHeight
        readonly property real minuteHeight: hourHeight / 60
        readonly property Item vScrollBar: QQC2.ScrollBar.vertical

        property int actualHeight: {
            let h = viewColumn.height - headerBottomSeparator.height - headerTopSeparator.height - headingRow.height;
            if (allDayHeader.visible) {
                h -= allDayHeader.height;
            }
            return h;
        }

        function setToCurrentTime(): void {
            setPosition(Math.max(0, (new Date()).getHours() - 1) / 23);
        }

        function currentPosition(): real {
            return vScrollBar.position;
        }

        function setPosition(position: real): void {
            let offset = vScrollBar.visualSize + position - 1;
            // Initially let's assume that we are still somewhere before bottom of the hourlyView
            // so lets simply set vScrollBar position to what was given

            let yPos = position;
            if (offset > 0) {
                // Ups, it seems that we are going lower than bottom of the hourlyView
                // Lets set position to the bottom of the vScrollBar then
                yPos = 1 - vScrollBar.visualSize;
            }

            vScrollBar.position = yPos;
        }

        Component.onCompleted: {
            if (!Kirigami.Settings.isMobile) {
                viewColumn.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
            }

            if(currentTimeMarkerLoader.active && viewColumn.initialWeek) {
                setToCurrentTime();
            }
        }

        NumberAnimation on QQC2.ScrollBar.vertical.position {
            id: scrollAnimation
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }

        Connections {
            target: hourlyView.QQC2.ScrollBar.vertical
            function onWidthChanged() {
                if(!Kirigami.Settings.isMobile) viewColumn.scrollbarWidth = hourlyView.QQC2.ScrollBar.vertical.width;
            }
        }

        Item {
            id: hourlyViewContents
            width: parent.width
            implicitHeight: hourlyView.dayHeight

            clip: true

            Item {
                id: hourLabelsColumn

                property real currentTimeLabelTop: currentTimeLabelLoader.active ?
                    currentTimeLabelLoader.item.y
                    : 0
                property real currentTimeLabelBottom: currentTimeLabelLoader.active ?
                    currentTimeLabelLoader.item.y + fontMetrics.height
                    : 0

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: viewColumn.hourLabelWidth

                Loader {
                    id: currentTimeLabelLoader

                    active: currentTimeMarkerLoader.active
                    sourceComponent: QQC2.Label {
                        id: currentTimeLabel

                        width: viewColumn.hourLabelWidth
                        color: Kirigami.Theme.highlightColor
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        rightPadding: Kirigami.Units.smallSpacing
                        y: Math.max(0, (viewColumn.currentDate.getHours() * viewColumn.gridLineWidth) + (hourlyView.minuteHeight * viewColumn.minutesFromStartOfDay) - (implicitHeight / 2)) - (viewColumn.gridLineWidth / 2)
                        z: 100

                        text: viewColumn.currentDate.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)

                    }
                }

                Repeater {
                    model: viewColumn.hourLabels

                    delegate: QQC2.Label {
                        property real textYTop: y
                        property real textYBottom: y + fontMetrics.height
                        property bool overlapWithCurrentTimeLabel: currentTimeLabelLoader.active &&
                            ((hourLabelsColumn.currentTimeLabelTop <= textYTop && hourLabelsColumn.currentTimeLabelBottom >= textYTop) ||
                            (hourLabelsColumn.currentTimeLabelTop < textYBottom && hourLabelsColumn.currentTimeLabelBottom > textYBottom) ||
                            (hourLabelsColumn.currentTimeLabelTop >= textYTop && hourLabelsColumn.currentTimeLabelBottom <= textYBottom))

                        y: ((viewColumn.periodHeight * hourlyView.periodsPerHour) * (index + 1)) + (viewColumn.gridLineWidth * (index + 1)) -
                            (fontMetrics.height / 2) - (viewColumn.gridLineWidth / 2)
                        width: viewColumn.hourLabelWidth
                        rightPadding: Kirigami.Units.smallSpacing
                        verticalAlignment: Text.AlignBottom
                        horizontalAlignment: Text.AlignRight
                        text: modelData
                        color: Kirigami.Theme.disabledTextColor
                        visible: !overlapWithCurrentTimeLabel
                    }
                }
            }

            Item {
                id: innerWeekView
                anchors {
                    left: hourLabelsColumn.right
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                clip: true

                Kirigami.Separator {
                    anchors.fill: parent
                }

                Row {
                    id: dayColumnRow
                    anchors.fill: parent
                    spacing: viewColumn.gridLineWidth

                    Repeater {
                        id: dayColumnRepeater
                        model: Calendar.HourlyIncidenceModel {
                           periodLength: viewColumn.periodLength
                           filters: Calendar.MultiDayIncidenceModel.AllDayOnly | Calendar.MultiDayIncidenceModel.MultiDayOnly
                           showTodos: Calendar.Config.showTodosInCalendarViews
                           showSubTodos: Calendar.Config.showSubtodosInCalendarViews
                           active: viewColumn.isCurrentItem
                           model: Calendar.IncidenceOccurrenceModel {
                               start: viewColumn.startDate
                               length: viewColumn.daysToShow
                               calendar: Calendar.CalendarManager.calendar
                               filter: Calendar.Filter
                           }
                        }

                        delegate: Item {
                            id: dayColumn

                            required property int index
                            required property var incidences
                            required property var periodStartDateTime

                            readonly property date columnDate: Calendar.DateUtils.addDaysToDate(viewColumn.startDate, index)
                            readonly property string formatedDate: Qt.formatDate(columnDate, 'yyyy-MM-dd')
                            readonly property bool isHoliday: formatedDate in Calendar.HolidayModel.holidays
                            readonly property bool isToday: columnDate.getDate() === viewColumn.currentDate.getDate() &&
                                columnDate.getMonth() === viewColumn.currentDate.getMonth() &&
                                columnDate.getFullYear() === viewColumn.currentDate.getFullYear()

                            width: viewColumn.dayWidth
                            height: hourlyView.dayHeight
                            clip: true

                            Loader {
                                anchors.fill: parent
                                asynchronous: !viewColumn.isCurrentItem

                                ListView {
                                    anchors.fill: parent
                                    spacing: viewColumn.gridLineWidth
                                    boundsBehavior: Flickable.StopAtBounds
                                    interactive: false

                                    model: 24

                                    delegate: Rectangle {
                                        id: backgroundRectangle

                                        required property int index
                                        readonly property color bgColor: {
                                            if (Calendar.Config.showHolidaysInCalendarViews && dayColumn.isHoliday) {
                                                return Kirigami.Theme.negativeBackgroundColor
                                            } else if (dayColumn.isToday) {
                                                return Kirigami.Theme.activeBackgroundColor
                                            }
                                            return Kirigami.Theme.backgroundColor
                                        }

                                        width: parent.width
                                        height: hourlyView.hourHeight
                                        color: backgroundRectangle.bgColor

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 0
                                            z: 9999

                                            Repeater {
                                                id: dropAreaRepeater

                                                readonly property int minutes: 60 / model

                                                model: 4

                                                DropArea {
                                                    id: hourlyViewIncidenceDropArea
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    z: 9999
                                                    onDropped: (drop) => {
                                                        if(viewColumn.isCurrentItem) {
                                                            let incidenceWrapper = Calendar.CalendarManager.createIncidenceWrapper();
                                                            /* So when we drop the entire incidence card somewhere, we are dropping the delegate with object name "hourlyIncidenceDelegateBackgroundBackground" or "multiDayIncidenceDelegateBackgroundBackground" in case when all day event is converted to the hour incidence.
                                                             * However, when we are simply resizing, we are actually dropping the specific mouseArea within the delegate that handles
                                                             * the dragging for the incidence's bottom edge which has name "endDtResizeMouseArea". Hence why we check the object names
                                                             */
                                                            if(drop.source.objectName === "hourlyIncidenceDelegateBackgroundBackground") {
                                                                incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                                const pos = mapToItem(viewColumn, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                drop.source.caughtX = pos.x + incidenceSpacing;
                                                                drop.source.caughtY = pos.y + incidenceSpacing;
                                                                drop.source.caught = true;

                                                                // We want the date as if it were "from the top" of the droparea
                                                                const posDate = new Date(backgroundDayTapHandler.addDate.getFullYear(), backgroundDayTapHandler.addDate.getMonth(), backgroundDayTapHandler.addDate.getDate(), backgroundRectangle.index, dropAreaRepeater.minutes * index);

                                                                const startOffset = posDate.getTime() - drop.source.occurrenceDate.getTime();

                                                                if (Calendar.DateUtils.sameDay(drop.source.occurrenceDate, posDate)
                                                                    && Calendar.DateUtils.sameTime(drop.source.occurrenceDate, posDate)) {
                                                                    return;
                                                                }

                                                                Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, startOffset, drop.source.occurrenceDate, drop.source);
                                                            } else if(drop.source.objectName === "multiDayIncidenceDelegateBackgroundBackground") {
                                                                incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.incidencePtr);

                                                                const pos = mapToItem(viewColumn, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                drop.source.caughtX = pos.x + incidenceSpacing;
                                                                drop.source.caughtY = pos.y + incidenceSpacing;
                                                                drop.source.caught = true;

                                                                // We want the date as if it were "from the top" of the droparea
                                                                const startPosDate = new Date(backgroundDayTapHandler.addDate.getFullYear(), backgroundDayTapHandler.addDate.getMonth(), backgroundDayTapHandler.addDate.getDate(), backgroundRectangle.index, dropAreaRepeater.minutes * index);
                                                                // In case when incidence is converted to not be all day anymore, lets set it as 1h long
                                                                const endPosDate = new Date(backgroundDayTapHandler.addDate.getFullYear(), backgroundDayTapHandler.addDate.getMonth(), backgroundDayTapHandler.addDate.getDate(), backgroundRectangle.index + 1, dropAreaRepeater.minutes * index);

                                                                const startOffset = startPosDate.getTime() - drop.source.occurrenceDate.getTime();
                                                                const endOffset = endPosDate.getTime() - drop.source.occurrenceEndDate.getTime();

                                                                Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, startOffset, endOffset, drop.source.occurrenceDate, drop.source);

                                                            } else { // The resize affects the end time
                                                                incidenceWrapper.incidenceItem = Calendar.CalendarManager.incidenceItem(drop.source.resizerSeparator.parent.incidencePtr);

                                                                const pos = mapToItem(drop.source.resizerSeparator.parent, dropAreaHighlightRectangle.x, dropAreaHighlightRectangle.y);
                                                                drop.source.resizerSeparator.parent.caughtHeight = (pos.y + dropAreaHighlightRectangle.height - incidenceSpacing)
                                                                drop.source.resizerSeparator.parent.caught = true;

                                                                // We want the date as if it were "from the bottom" of the droparea
                                                                const minute = (dropAreaRepeater.minutes * (index + 1)) % 60;
                                                                const isNextHour = minute === 0 && index !== 0;
                                                                const hour = isNextHour ? backgroundRectangle.index + 1 : backgroundRectangle.index;

                                                                const posDate = new Date(backgroundDayTapHandler.addDate.getFullYear(), backgroundDayTapHandler.addDate.getMonth(), backgroundDayTapHandler.addDate.getDate(), hour, minute);

                                                                const endOffset = posDate.getTime() - drop.source.resizerSeparator.parent.occurrenceEndDate.getTime();

                                                                Calendar.CalendarUiUtils.setUpIncidenceDateChange(incidenceWrapper, 0, endOffset, drop.source.resizerSeparator.parent.occurrenceDate, drop.source.resizerSeparator.parent);
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        id: dropAreaHighlightRectangle
                                                        anchors.fill: parent
                                                        color: Kirigami.Theme.positiveBackgroundColor
                                                        visible: hourlyViewIncidenceDropArea.containsDrag
                                                    }
                                                }
                                            }
                                        }

                                        Calendar.DayTapHandler {
                                            id: backgroundDayTapHandler
                                            addDate: new Date(Calendar.DateUtils.addDaysToDate(viewColumn.startDate, dayColumn.index).setHours(backgroundRectangle.index))
                                            onDeselect: Calendar.CalendarUiUtils.appMain.incidenceInfoViewer.close()
                                        }
                                    }
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                asynchronous: !viewColumn.isCurrentItem
                                Repeater {
                                    id: hourlyIncidencesRepeater
                                    model: dayColumn.incidences

                                    delegate: Rectangle {
                                        id: hourlyIncidenceDelegateBackgroundBackground
                                        objectName: "hourlyIncidenceDelegateBackgroundBackground"

                                        readonly property int initialIncidenceHeight: (modelData.duration * viewColumn.periodHeight) - (viewColumn.incidenceSpacing * 2) + gridLineHeightCompensation - viewColumn.gridLineWidth
                                        readonly property real gridLineYCompensation: (modelData.starts / hourlyView.periodsPerHour) * viewColumn.gridLineWidth
                                        readonly property real gridLineHeightCompensation: (modelData.duration / hourlyView.periodsPerHour) * viewColumn.gridLineWidth
                                        property bool isOpenOccurrence: viewColumn.openOccurrence ?
                                            viewColumn.openOccurrence.incidenceId === modelData.incidenceId : false

                                        x: viewColumn.incidenceSpacing + (modelData.priorTakenWidthShare * viewColumn.dayWidth)
                                        y: (modelData.starts * viewColumn.periodHeight) + viewColumn.incidenceSpacing + gridLineYCompensation
                                        width: (viewColumn.dayWidth * modelData.widthShare) - (viewColumn.incidenceSpacing * 2)
                                        height: initialIncidenceHeight
                                        radius: Kirigami.Units.smallSpacing
                                        color: Qt.rgba(0,0,0,0)
                                        visible: !modelData.allDay

                                        property alias mouseArea: mouseArea
                                        property var incidencePtr: modelData.incidencePtr
                                        property date occurrenceDate: modelData.startTime
                                        property date occurrenceEndDate: modelData.endTime
                                        property bool repositionAnimationEnabled: false
                                        property bool caught: false
                                        property real caughtX: x
                                        property real caughtY: y
                                        property real caughtHeight: height
                                        property real resizeHeight: height

                                        Drag.active: mouseArea.drag.active
                                        Drag.hotSpot.x: mouseArea.mouseX

                                        // Drag reposition animations -- when the incidence goes to the correct cell of the hourly grid
                                        Behavior on x {
                                            enabled: repositionAnimationEnabled
                                            NumberAnimation {
                                                duration: Kirigami.Units.shortDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on y {
                                            enabled: repositionAnimationEnabled
                                            NumberAnimation {
                                                duration: Kirigami.Units.shortDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on height {
                                            enabled: repositionAnimationEnabled
                                            NumberAnimation {
                                                duration: Kirigami.Units.shortDuration
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        states: [
                                            State {
                                                when: hourlyIncidenceDelegateBackgroundBackground.mouseArea.drag.active
                                                ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: viewColumn }
                                                PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; isOpenOccurrence: true }
                                            },
                                            State {
                                                when: hourlyIncidenceResizer.mouseArea.drag.active
                                                PropertyChanges { target: hourlyIncidenceDelegateBackgroundBackground; height: resizeHeight }
                                            },
                                            State {
                                                when: hourlyIncidenceDelegateBackgroundBackground.caught
                                                ParentChange { target: hourlyIncidenceDelegateBackgroundBackground; parent: viewColumn }
                                                PropertyChanges {
                                                    target: hourlyIncidenceDelegateBackgroundBackground
                                                    repositionAnimationEnabled: true
                                                    x: caughtX
                                                    y: caughtY
                                                    height: caughtHeight
                                                }
                                            }
                                        ]

                                        Calendar.IncidenceDelegateBackground {
                                            id: incidenceDelegateBackground
                                            isOpenOccurrence: parent.isOpenOccurrence
                                            isDark: viewColumn.isDark
                                        }

                                        ColumnLayout {
                                            id: incidenceContents

                                            readonly property color textColor: isOpenOccurrence ?
                                                (Calendar.LabelUtils.isDarkColor(modelData.color) ? "white" : "black") :
                                                Calendar.LabelUtils.getIncidenceLabelColor(modelData.color, viewColumn.isDark)
                                            readonly property bool isTinyHeight: parent.height <= Kirigami.Units.gridUnit

                                            clip: true

                                            anchors {
                                                fill: parent
                                                leftMargin: Kirigami.Units.smallSpacing
                                                rightMargin: Kirigami.Units.smallSpacing
                                                topMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                                bottomMargin: !isTinyHeight ? Kirigami.Units.smallSpacing : 0
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                text: modelData.text
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignTop
                                                wrapMode: Text.Wrap
                                                elide: Text.ElideRight
                                                font.pointSize: parent.isTinyHeight ? Kirigami.Theme.smallFont.pointSize :
                                                    Kirigami.Theme.defaultFont.pointSize
                                                font.weight: Font.Medium
                                                font.strikeout: modelData.todoCompleted
                                                renderType: Text.QtRendering
                                                color: incidenceContents.textColor
                                                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                            }

                                            RowLayout {
                                                width: parent.width
                                                visible: parent.height > Kirigami.Units.gridUnit * 3
                                                Kirigami.Icon {
                                                    id: incidenceIcon
                                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                                    source: modelData.incidenceTypeIcon
                                                    isMask: true
                                                    color: incidenceContents.textColor
                                                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                    visible: parent.width > Kirigami.Units.gridUnit * 4
                                                }
                                                QQC2.Label {
                                                    id: timeLabel
                                                    Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignRight
                                                    text: modelData.startTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat) + "–" + modelData.endTime.toLocaleTimeString(Qt.locale(), Locale.NarrowFormat)
                                                    wrapMode: Text.Wrap
                                                    renderType: Text.QtRendering
                                                    color: incidenceContents.textColor
                                                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                                                    visible: parent.width > Kirigami.Units.gridUnit * 3
                                                }
                                            }
                                        }

                                        Calendar.IncidenceMouseArea {
                                            id: mouseArea
                                            preventStealing: !Kirigami.Settings.tabletMode && !Kirigami.Settings.isMobile
                                            incidenceData: modelData
                                            collectionId: modelData.collectionId

                                            drag.target: !Kirigami.Settings.isMobile && !modelData.isReadOnly && viewColumn.dragDropEnabled ? parent : undefined
                                            onReleased: parent.Drag.drop()

                                            onViewClicked: Calendar.CalendarUiUtils.setUpView(modelData, hourlyIncidenceDelegateBackgroundBackground)
                                            onDeleteClicked: Calendar.CalendarUiUtils.setUpDelete(incidencePtr, deleteDate)
                                            onTodoCompletedClicked: Calendar.CalendarUiUtils.completeTodo(incidencePtr)
                                        }

                                        Calendar.ResizerSeparator {
                                            id: hourlyIncidenceResizer
                                            objectName: "endDtResizeMouseArea"
                                            anchors.left: parent.left
                                            anchors.leftMargin: hourlyIncidenceDelegateBackgroundBackground.radius
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.rightMargin: hourlyIncidenceDelegateBackgroundBackground.radius
                                            height: 1
                                            oversizeMouseAreaVertical: 2
                                            z: Infinity
                                            enabled: !Kirigami.Settings.isMobile && !modelData.isReadOnly
                                            unhoveredColor: "transparent"

                                            onDragPositionChanged: parent.resizeHeight = Math.max(viewColumn.periodHeight, hourlyIncidenceDelegateBackgroundBackground.initialIncidenceHeight + changeY)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: currentTimeMarkerLoader

                    active: viewColumn.currentDate >= viewColumn.startDate && viewColumn.currentDate < viewColumn.endDate

                    sourceComponent: Rectangle {
                        id: currentTimeMarker

                        width: viewColumn.dayWidth
                        height: viewColumn.gridLineWidth * 2
                        color: Kirigami.Theme.highlightColor
                        x: (viewColumn.daysFromWeekStart * viewColumn.dayWidth) + (viewColumn.daysFromWeekStart * viewColumn.gridLineWidth)
                        y: (viewColumn.currentDate.getHours() * viewColumn.gridLineWidth) + (hourlyView.minuteHeight * viewColumn.minutesFromStartOfDay) -
                            (height / 2) - (viewColumn.gridLineWidth / 2)
                        z: 100

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: -(height / 2) + (parent.height / 2)
                            width: height
                            height: parent.height * 5
                            radius: 100
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }
            }
        }
    }
}
