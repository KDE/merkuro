// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects

import org.kde.merkuro.calendar as Calendar

PathView {
    id: root

    function updateCurrentView() {
        if (!root.currentItem) {
            return;
        }

        const position = root.currentItem.item.hourScrollView.currentPosition();
        const newIndex = model.moveToDate(selectedDate, currentItem.startDate, currentIndex);
        currentIndex = newIndex;

        if (initialWeek) {
            root.currentItem.item.hourScrollView.setToCurrentTime(true);
            initialWeek = false;
        } else {
            root.currentItem.item.hourScrollView.setPosition(position);
        }
    }

    required property var openOccurrence
    required property int daysToShow
    required property bool dragDropEnabled
    property real scrollPosition

    readonly property date selectedDate: if (daysToShow % 7 === 0) {
        Calendar.DateTimeState.firstDayOfWeek
    } else {
        Calendar.DateTimeState.selectedDate
    }
    onSelectedDateChanged: updateCurrentView()

    property bool initialWeek: true

    flickDeceleration: Kirigami.Units.longDuration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapToItem
    focus: true
    interactive: Kirigami.Settings.tabletMode

    pathItemCount: 3
    path: Path {
        startX: - root.width * root.pathItemCount / 2 + root.width / 2
        startY: root.height / 2
        PathLine {
            x: root.width * root.pathItemCount / 2 + root.width / 2
            y: root.height / 2
        }
    }

    model: Calendar.InfiniteMerkuroCalendarViewModel {
        scale: switch(root.daysToShow) {
        case 1:
            return Calendar.InfiniteMerkuroCalendarViewModel.DayScale;
        case 3:
            return Calendar.InfiniteMerkuroCalendarViewModel.ThreeDayScale;
        case 5:
            return Calendar.InfiniteMerkuroCalendarViewModel.WorkWeekScale;
        case 7:
        default:
            return Calendar.InfiniteMerkuroCalendarViewModel.WeekScale;
        }
    }

    onMovementStarted: scrollPosition = root.currentItem.item.hourScrollView.currentPosition();
    onMovementEnded: root.currentItem.item.hourScrollView.setPosition(scrollPosition);

    Component.onCompleted: updateCurrentView()

    delegate: Loader {
        id: viewLoader

        required property int index
        required property date startDate

        readonly property date endDate: Calendar.Utils.addDaysToDate(startDate, root.daysToShow)

        readonly property bool isCurrentItem: PathView.isCurrentItem
        readonly property bool isNextOrCurrentItem: index >= root.currentIndex -1 && index <= root.currentIndex + 1
        property int multiDayLinesShown: 0

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready

        sourceComponent: BasicInternalHourlyView {
            width: root.width
            height: root.height

            openOccurrence: root.openOccurrence
            daysToShow: root.daysToShow
            startDate: viewLoader.startDate
            dragDropEnabled: root.dragDropEnabled
            isCurrentItem: viewLoader.isCurrentItem
        }
    }
}

