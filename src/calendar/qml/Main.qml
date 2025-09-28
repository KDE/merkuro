// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtCore 6.5
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQml.Models 2.15
import Qt.labs.platform

import org.kde.merkuro.calendar
import org.kde.merkuro.components

BaseApplication {
    id: root

    application: CalendarApplication

    property var openOccurrence: {}

    readonly property var monthViewAction: CalendarApplication.action("open_month_view")
    readonly property var weekViewAction: CalendarApplication.action("open_week_view")
    readonly property var workWeekViewAction: CalendarApplication.action("open_workweek_view")
    readonly property var threeDayViewAction: CalendarApplication.action("open_threeday_view")
    readonly property var dayViewAction: CalendarApplication.action("open_day_view")
    readonly property var scheduleViewAction: CalendarApplication.action("open_schedule_view")
    readonly property var todoViewAction: CalendarApplication.action("open_todo_view")
    readonly property var moveViewForwardsAction: CalendarApplication.action("move_view_forwards")
    readonly property var moveViewBackwardsAction: CalendarApplication.action("move_view_backwards")
    readonly property var moveViewToTodayAction: CalendarApplication.action("move_view_to_today")
    readonly property var aboutPageAction: CalendarApplication.action("open_about_page")
    readonly property var toggleMenubarAction: CalendarApplication.action("toggle_menubar")
    readonly property var createEventAction: CalendarApplication.action("create_event")
    readonly property var createTodoAction: CalendarApplication.action("create_todo")
    readonly property var configureAction: CalendarApplication.action("options_configure")
    readonly property var undoAction: CalendarApplication.action("edit_undo")
    readonly property var redoAction: CalendarApplication.action("edit_redo")
    readonly property var refreshAllAction: CalendarApplication.action("refresh_all")

    readonly property var todoViewSortAlphabeticallyAction: CalendarApplication.action("todoview_sort_alphabetically")
    readonly property var todoViewSortByDueDateAction: CalendarApplication.action("todoview_sort_by_due_date")
    readonly property var todoViewSortByPriorityAction: CalendarApplication.action("todoview_sort_by_priority")
    readonly property var todoViewOrderAscendingAction: CalendarApplication.action("todoview_order_ascending")
    readonly property var todoViewOrderDescendingAction: CalendarApplication.action("todoview_order_descending")
    readonly property var todoViewShowCompletedAction: CalendarApplication.action("todoview_show_completed")
    readonly property var tagManagerAction: CalendarApplication.action("open_tag_manager")

    readonly property int mode: applicationWindow().pageStack.currentItem ? applicationWindow().pageStack.currentItem.mode : CalendarApplication.Event

    function switchView(view, viewSettings) {
        if (root.pageStack.layers.depth > 1) {
            root.pageStack.layers.pop(root.pageStack.layers.initialItem);
        }
        if (root.pageStack.depth > 1) {
            root.pageStack.pop();
        }
        root.pageStack.replace(view, viewSettings);

        if (root.filterHeaderBarLoaderItem.active) {
            root.pageStack.currentItem.header = root.filterHeaderBarLoaderItem.item;
        }
    }

    pageStack.initialPage: scheduleViewComponent

    property bool ignoreCurrentPage: true // HACK: ideally we just push an empty page here and save ourselves the trouble,
    // but we have had issues with pushing empty Kirigami pages somehow causing mobile controls to show up on desktop.
    // We use this property to temporarily allow a view to be replaced by a view of the same type

    Component.onCompleted: {
        CalendarApplication.calendar = CalendarManager.calendar
        CalendarUiUtils.appMain = root; // Most of our util functions use things defined here in main

        HolidayModel.holidayRegions = Config.holidayRegions;

        if (Config.lastOpenedView === -1) {
            Kirigami.Settings.isMobile ? scheduleViewAction.trigger() : monthViewAction.trigger();
            return;
        }

        switch (Config.lastOpenedView) {
            case Config.MonthView:
                monthViewAction.trigger();
                break;
            case Config.WeekView:
                weekViewAction.trigger();
                break;
            case Config.WorkWeekView:
                workWeekViewAction.trigger();
                break;
            case Config.ThreeDayView:
                threeDayViewAction.trigger();
                break;
            case Config.DayView:
                dayViewAction.trigger();
                break;
            case Config.ScheduleView:
                scheduleViewAction.trigger();
                break;
            case Config.TodoView:
                todoViewAction.trigger();
                break;
            default:
                Kirigami.Settings.isMobile ? scheduleViewAction.trigger() : monthViewAction.trigger();
                break;
        }
        ignoreCurrentPage = false;
    }

    Connections {
        target: Config

        function onHolidayRegionsChanged(): void {
            HolidayModel.holidayRegions = Config.holidayRegions;
        }
    }

    QQC2.Action {
        id: deleteIncidenceAction
        shortcut: "Delete"
        onTriggered: {
            if(root.openOccurrence) {
                CalendarUiUtils.setUpDelete(root.openOccurrence.incidencePtr,
                                            root.openOccurrence.startTime);
            }
        }
    }

    KBMNavigationMouseArea {
        id: kbmNavigationMouseArea
        anchors.fill: parent
    }

    Connections {
        target: CalendarApplication

        function onOpenMonthView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.Month || root.ignoreCurrentPage) {
                root.switchView(monthViewComponent);
            }
        }

        function onOpenWeekView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.Week || root.ignoreCurrentPage) {
                root.switchView(hourlyViewComponent, { createEventAction: root.createAction} );
            }
        }

        function onOpenWorkWeekView(): void {
            // Assuming WorkWeek uses HourlyView with 5 days
            if(root.pageStack.currentItem.mode !== CalendarApplication.WorkWeek || root.ignoreCurrentPage) {
                root.switchView(hourlyViewComponent, { daysToShow: 5, createEventAction: root.createAction });
            }
        }

        function onOpenThreeDayView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.ThreeDay || root.ignoreCurrentPage) {
                root.switchView(hourlyViewComponent, { daysToShow: 3, createEventAction: root.createAction });
            }
        }

        function onOpenDayView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.Day || root.ignoreCurrentPage) {
                root.switchView(hourlyViewComponent, { daysToShow: 1, createEventAction: root.createAction });
            }
        }

        function onOpenScheduleView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.Schedule || root.ignoreCurrentPage) {
                root.switchView(scheduleViewComponent);
            }
        }

        function onOpenTodoView(): void {
            if(root.pageStack.currentItem.mode !== CalendarApplication.Todo) {
                filterHeaderBar.active = true;
                root.switchView(todoViewComponent);
            }
        }

        function onMoveViewForwards(): void {
            root.pageStack.currentItem.nextAction.trigger();
        }

        function onMoveViewBackwards(): void {
            root.pageStack.currentItem.previousAction.trigger();
        }

        function onMoveViewToToday(): void {
            root.pageStack.currentItem.todayAction.trigger();
        }

        function onCreateNewEvent(): void {
            IncidenceEditorManager.openNewIncidenceEditorDialog(root, IncidenceWrapper.TypeEvent);
        }

        function onCreateNewTodo(): void {
            IncidenceEditorManager.openNewIncidenceEditorDialog(root, IncidenceWrapper.TypeTodo);
        }

        function onUndo(): void {
            CalendarManager.undoAction();
        }

        function onRedo(): void {
            CalendarManager.redoAction();
        }

        function onTodoViewSortAlphabetically(): void {
            Config.sort = Config.Alphabetically;
            Config.save();
        }

        function onTodoViewSortByDueDate(): void {
            Config.sort = Config.DueTime;
            Config.save();
        }

        function onTodoViewSortByPriority(): void {
            Config.sort = Config.Priority;
            Config.save();
        }

        function onTodoViewOrderAscending(): void {
            Config.ascendingOrder = true;
            Config.save();
        }

        function onTodoViewOrderDescending(): void {
            Config.ascendingOrder = false;
            Config.save();
        }

        function onTodoViewShowCompleted(): void {
            const openDialogWindow = root.pageStack.pushDialogLayer(root.pageStack.currentItem.completedSheetComponent);
            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

        function onConfigureSchedule(): void {
            configurationsView.open("freebusy");
        }

        function onOpenSettings(): void {
            configurationsView.open();
        }

        function onRefreshAll(): void {
            CalendarManager.updateAllCollections();
        }

        function onOpenIncidence(incidenceData, occurrenceDate): void {
            // Switch to an event view if the current view is not compatible with the current incidence type
            if (root.pageStack.currentItem.mode & (CalendarApplication.Todo | CalendarApplication.Event) ||
                (root.pageStack.currentItem.mode === CalendarApplication.Todo && incidenceData.incidenceType !== IncidenceWrapper.TypeTodo)) {

                Kirigami.Settings.isMobile ? root.dayViewAction.trigger() : root.weekViewAction.trigger();
            }

            CalendarUiUtils.setUpView(incidenceData);
            DateTimeState.selectedDate = occurrenceDate;
        }
    }

    Connections {
        target: CalendarManager

        function onUndoRedoDataChanged() {
            root.undoAction.enabled = CalendarManager.undoRedoData.undoAvailable;
            root.redoAction.enabled = CalendarManager.undoRedoData.redoAvailable;
        }

        function onErrorOccurred(error: string): void {
            root.showPassiveNotification(error);
        }
    }

    ConfigurationsView {
        id: configurationsView
    }

    property Kirigami.Action createAction: Kirigami.Action {
        text: i18nc("@action:button", "Create")
        icon.name: "list-add"

        Kirigami.Action {
            id: newEventAction
            text: i18nc("@action:button", "New Event…")
            icon.name: "resource-calendar-insert"
            onTriggered: root.createEventAction.trigger()
        }
        Kirigami.Action {
            id: newTodoAction
            text: i18nc("@action:button", "New Task…")
            icon.name: "view-task-add"
            onTriggered: root.createTodoAction.trigger()
        }
    }

    title: if(pageStack.currentItem) {
        switch (pageStack.currentItem.mode) {
            case CalendarApplication.Month:
                return i18nc("@title", "Month");

            case CalendarApplication.Week:
                return i18nc("@title", "Week");

            case CalendarApplication.WorkWeek:
                return i18nc("@title", "Work Week");

            case CalendarApplication.ThreeDay:
                return i18nc("@title", "3 Days");

            case CalendarApplication.Day:
                return i18nc("@title", "Day");

            case CalendarApplication.Schedule:
                return i18nc("@title", "Schedule");

            case CalendarApplication.Todo:
                return i18nc("@title", "Tasks");

            default:
                // Should not happen
                return 'Calendar';
        }
    } else {
        return 'Calendar';
    }

    menubarComponent: MenuBar {}

    Loader {
        id: globalMenuLoader
        active: !Kirigami.Settings.isMobile

        sourceComponent: GlobalMenuBar {}
    }

    footer: Loader {
        id: bottomLoader
        active: Kirigami.Settings.isMobile
        visible: root.pageStack.currentItem && root.pageStack.layers.currentItem.objectName !== "settingsPage"

        sourceComponent: BottomToolBar {}
    }

    property alias mainDrawer: mainDrawer
    globalDrawer: MainDrawer {
        id: mainDrawer
        mode: root.pageStack.currentItem ? root.pageStack.currentItem.mode : CalendarApplication.Event
    }

    contextDrawer: root.incidenceInfoDrawerEnabled ? incidenceInfoDrawer : null

    readonly property var incidenceInfoViewer: incidenceInfoDrawerEnabled ? incidenceInfoDrawer :
        incidenceInfoPopupEnabled ? incidenceInfoPopup :
        null

    property bool incidenceInfoDrawerEnabled: Kirigami.Settings.isMobile || !Config.useIncidenceInfoPopup
    readonly property alias incidenceInfoDrawer: incidenceInfoDrawerLoader.item
    Loader {
        id: incidenceInfoDrawerLoader
        active: root.incidenceInfoDrawerEnabled
        sourceComponent: IncidenceInfoDrawer {
            id: incidenceInfoDrawer

            readonly property int minWidth: Kirigami.Units.gridUnit * 15
            readonly property int maxWidth: Kirigami.Units.gridUnit * 25
            readonly property int defaultWidth: Kirigami.Units.gridUnit * 20
            property int actualWidth: {
                if (Config.incidenceInfoDrawerDrawerWidth && Config.incidenceInfoDrawerDrawerWidth === -1) {
                    return defaultWidth;
                } else {
                    return Config.incidenceInfoDrawerDrawerWidth;
                }
            }

            width: Kirigami.Settings.isMobile ? parent.width : actualWidth
            height: Kirigami.Settings.isMobile 
                ? root.QQC2.ApplicationWindow.window.height * 0.6
                : (parent.height - (root.menuBar.active ? root.menuBar.height : 0)) // Work around incorrect height calculation when menu bar active

            modal: !root.wideScreen || !enabled
            onEnabledChanged: drawerOpen = enabled && !modal
            onModalChanged: drawerOpen = !modal
            enabled: incidenceData !== undefined && root.pageStack.currentItem && root.pageStack.currentItem.mode !== CalendarApplication.Contact
            handleVisible: enabled
            interactive: Kirigami.Settings.isMobile // Otherwise get weird bug where drawer gets dragged around despite no click

            onIncidenceDataChanged: root.openOccurrence = incidenceData;
            onVisibleChanged: visible ? root.openOccurrence = incidenceData : root.openOccurrence = null

            ResizerSeparator {
                anchors.left: if(Application.layoutDirection !== Qt.RightToLeft) parent.left
                anchors.leftMargin: if(Application.layoutDirection !== Qt.RightToLeft) -1 // Cover up the natural separator on the drawer
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: if(Application.layoutDirection === Qt.RightToLeft) parent.right
                anchors.rightMargin: if(Application.layoutDirection === Qt.RightToLeft) -1
                width: 1
                oversizeMouseAreaHorizontal: 5
                z: 500

                function savePos() {
                    Config.incidenceInfoDrawerDrawerWidth = incidenceInfoDrawer.actualWidth;
                    Config.save();
                }

                onDragBegin: savePos()
                onDragReleased: savePos()

                onDragPositionChanged: (changeX, changeY) => {
                    if (Application.layoutDirection === Qt.RightToLeft) {
                        incidenceInfoDrawer.actualWidth = Math.min(incidenceInfoDrawer.maxWidth, Math.max(incidenceInfoDrawer.minWidth, Config.incidenceInfoDrawerDrawerWidth + changeX));
                    } else {
                        incidenceInfoDrawer.actualWidth = Math.min(incidenceInfoDrawer.maxWidth, Math.max(incidenceInfoDrawer.minWidth, Config.incidenceInfoDrawerDrawerWidth - changeX));
                    }
                }
            }
        }
    }

    property bool incidenceInfoPopupEnabled: !Kirigami.Settings.isMobile && Config.useIncidenceInfoPopup
    readonly property alias incidenceInfoPopup: incidenceInfoPopupLoader.item
    Loader {
        id: incidenceInfoPopupLoader
        active: root.incidenceInfoPopupEnabled
        sourceComponent: IncidenceInfoPopup {
            id: incidenceInfoPopup

            // HACK: This is called on mouse events by the KBMNavigationMouseArea in root
            // so that we can react to scrolling in the different views, as there is no
            // way to track the assigned incidence item delegate in a global sense.
            // Remember that when a delegate is scrolled within a scroll view, the
            // delegate's own relative x and y values do not change
            function reposition() {
                calculatePositionTimer.start();
            }

            function calculateIncidenceItemPosition() {
                if (!openingIncidenceItem) {
                    console.log("Can't calculate incidence item position for popup, no opening incidence item is set");
                    close();
                    return;
                }

                // We need to compensate for the x and y local adjustments used, for instance,
                // in the day grid view to position the incidence item delegates
                incidenceItemPosition = openingIncidenceItem.mapToItem(parent,
                                                                       openingIncidenceItem.x,
                                                                       openingIncidenceItem.y);
                incidenceItemPosition.x -= openingIncidenceItem.x;
                incidenceItemPosition.y -= openingIncidenceItem.y;
            }

            property Item openingIncidenceItem: null
            onOpeningIncidenceItemChanged: reposition()

            property point incidenceItemPosition
            property point clickPosition
            property int incidenceItemMidXPoint: incidenceItemPosition && openingIncidenceItem ?
                incidenceItemPosition.x + openingIncidenceItem.width / 2 : 0
            property bool positionBelowIncidenceItem: root.pageStack.currentItem
                ? incidenceItemPosition && incidenceItemPosition.y < root.pageStack.currentItem.height / 2
                : 0;
            property bool positionAtIncidenceItemCenter: openingIncidenceItem &&
                openingIncidenceItem.width < width
            property int maxXPosition: root.pageStack.currentItem ? root.pageStack.currentItem.width - width : 0

            // HACK:
            // If we reposition immediately we often end up updating the position of the popup
            // before the assigned delegate has finished changing position itself. Even with
            // this tiny interval, we avoid the problem and 2ms is not enough to be noticeable
            Timer {
                id: calculatePositionTimer
                interval: 2
                onTriggered: incidenceInfoPopup.calculateIncidenceItemPosition()
            }

            Connections {
                target: incidenceInfoPopup.openingIncidenceItem
                function onXChanged() { incidenceInfoPopup.reposition(); }
                function onYChanged() { incidenceInfoPopup.reposition(); }
                function onWidthChanged() { incidenceInfoPopup.reposition(); }
                function onHeightChanged() { incidenceInfoPopup.reposition(); }
            }

            x: {
                if(positionAtIncidenceItemCenter) {
                    // Center the popup on the incidence item if possible, but also ensure
                    // it is not going further left or right than the left and right edges
                    // of the current view
                    return Math.max(0, Math.min(incidenceItemMidXPoint - width / 2, maxXPosition));

                } else if(openingIncidenceItem) {
                    const itemLeft = mapFromItem(openingIncidenceItem, 0, 0).x;
                    const itemRight = mapFromItem(openingIncidenceItem, openingIncidenceItem.width, 0).x;

                    return Math.max(itemLeft, Math.min(clickPosition.x, itemRight - width));
                }

                return 0;
            }
            // Make sure not to cover up the incidence item
            y: positionBelowIncidenceItem && openingIncidenceItem ? incidenceItemPosition.y + openingIncidenceItem.height : incidenceItemPosition.y - height;

            width: Math.min(root.pageStack.currentItem.width, Kirigami.Units.gridUnit * 30)
            height: Math.min(Kirigami.Units.gridUnit * 16, implicitHeight)

            onIncidenceDataChanged: root.openOccurrence = incidenceData
            onVisibleChanged: {
                if (visible) {
                    clickPosition = mapFromGlobal(MouseTracker.mousePosition)
                    root.openOccurrence = incidenceData;
                    reposition();
                } else {
                    root.openOccurrence = null;
                    // Unlike the drawer we are not going to reopen the popup without selecting an incidence
                    incidenceData = null;
                }
            }
        }
    }

    property alias filterHeaderBarLoaderItem: filterHeaderBar
    Loader {
        id: filterHeaderBar
        active: false
        sourceComponent: Item {
            readonly property bool show: header.mode === CalendarApplication.Todo ||
                                         Filter.tags.length > 0 ||
                                         notifyMessage.visible
            readonly property alias messageItem: notifyMessage

            height: show ? headerLayout.implicitHeight + headerSeparator.height : 0
            // Adjust for margins
            clip: height === 0

            Behavior on height { NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            } }

            Rectangle {
                width: headerLayout.width
                height: headerLayout.height
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.backgroundColor
            }

            ColumnLayout {
                id: headerLayout
                anchors.fill: parent
                clip: true

                Kirigami.InlineMessage {
                    id: notifyMessage
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    showCloseButton: true
                    visible: false
                }

                FilterHeaderBar {
                    id: header
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    mode: root.pageStack.currentItem ? root.pageStack.currentItem.mode : CalendarApplication.Event
                    isDark: CalendarUiUtils.darkMode
                    clip: true
                }
            }
            Kirigami.Separator {
                id: headerSeparator
                anchors.top: headerLayout.bottom
                width: parent.width
                height: 1
                z: -2
            }
        }
    }

    Connections {
        target: CalendarManager
        function onUpdateIncidenceDatesCompleted() { CalendarUiUtils.reenableDragOnCurrentView(); }
    }

    property Component deleteIncidenceDialogComponent: DeleteIncidenceDialog {
        function closeOpenIncidenceIfSame() {
            const deletingIncidenceIsOpen = incidenceWrapper &&
                                            root.incidenceInfoViewer &&
                                            root.incidenceInfoViewer.incidenceWrapper &&
                                            root.incidenceInfoViewer.incidenceWrapper.uid === incidenceWrapper.uid;

            if (deletingIncidenceIsOpen) {
                root.incidenceInfoViewer.incidenceData = undefined;
                root.openOccurrence = undefined;
            }
        }

        onAddException: (exceptionDate, incidenceWrapper) => {
            if (root.openOccurrence && DateUtils.sameDay(root.openOccurrence.incidenceData.startTime, exceptionDate)) {
                closeOpenIncidenceIfSame()
            }

            incidenceWrapper.recurrenceExceptionsModel.addExceptionDateTime(exceptionDate);
            CalendarManager.editIncidence(incidenceWrapper);
            close();
            destroy();
        }
        onAddRecurrenceEndDate: (endDate, incidenceWrapper) => {
            // If occurrence is past the new recurrence end date, it has ben deleted so kill instance in incidence info
            if (root.openOccurrence && root.openOccurrence.startTime >= endDate) {
                closeOpenIncidenceIfSame();
            }

            incidenceWrapper.setRecurrenceDataItem("endDateTime", endDate);
            CalendarManager.editIncidence(incidenceWrapper);
            close();
            destroy();
        }
        onDeleteIncidence: (incidencePtr) => {
            // Deleting an incidence also means deleting all of its occurrences
            closeOpenIncidenceIfSame()
            CalendarManager.deleteIncidence(incidencePtr);
            close();
            destroy();
        }
        onDeleteIncidenceWithChildren: (incidencePtr) => {
            // TODO: Check if parent deleted too
            closeOpenIncidenceIfSame();
            CalendarManager.deleteIncidence(incidencePtr, true);
            close();
            destroy();
        }
        onCancel: {
            close();
            destroy()
        }
    }

    property alias recurringIncidenceChangePageComponent: recurringIncidenceChangePageComponent
    Component {
        id: recurringIncidenceChangePageComponent
        RecurringIncidenceChangePage {
            id: recurringIncidenceChangePage

            onChangeAll: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.AllOccurrences);
                closeDialog();
            }
            onChangeThis: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.SelectedOccurrence, occurrenceDate);
                closeDialog();
            }
            onChangeThisAndFuture: {
                CalendarManager.updateIncidenceDates(incidenceWrapper, startOffset, endOffset, IncidenceWrapper.FutureOccurrences, occurrenceDate);
                closeDialog();
            }
            onCancel: {
                caughtDelegate.caught = false;
                CalendarUiUtils.reenableDragOnCurrentView();
                closeDialog();
            }
        }
    }

    Component {
        id: monthViewComponent

        MonthView {
            id: monthView
            objectName: "monthView"

            openOccurrence: root.openOccurrence
            createEventAction: root.createAction
        }
    }

    Component {
        id: hourlyViewComponent

        HourlyView {
            id: monthView
            objectName: "hourlyView"

            createEventAction: root.createAction
        }
    }


    Component {
        id: scheduleViewComponent

        ScheduleView {
            id: scheduleView
            objectName: "scheduleView"

            openOccurrence: root.openOccurrence
            createEventAction: root.createAction
        }
    }

    Component {
        id: todoViewComponent

        TodoView {
            id: todoView
            objectName: "todoView"
        }
    }

    property ImportHandler importHandler: ImportHandler {
        objectName: "ImportHandler"
    }

    property Item hoverLinkIndicator: QQC2.Control {
        parent: root.overlay.parent
        property alias text: linkText.text
        opacity: text.length > 0 ? 1 : 0

        z: 99999
        x: 0
        y: parent.height - implicitHeight
        contentItem: QQC2.Label {
            id: linkText
        }
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        background: Rectangle {
             color: Kirigami.Theme.backgroundColor
        }
    }
}
