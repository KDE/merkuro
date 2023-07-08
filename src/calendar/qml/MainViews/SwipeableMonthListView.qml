// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami

import org.kde.kalendar.calendar 1.0 as Calendar
import org.kde.kalendar.utils 1.0

PathView {
    id: root

    required property var openOccurrence
    required property bool dragDropEnabled

    flickDeceleration: Kirigami.Units.longDuration
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
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

    model: Calendar.InfiniteCalendarViewModel {
        scale: Calendar.InfiniteCalendarViewModel.MonthScale
    }

    Component.onCompleted: currentIndex = count / 2;
    onCurrentIndexChanged: if (currentIndex >= count - 2) {
        model.addDates(true);
    } else if (currentIndex <= 2) {
        model.addDates(false);
    }

    delegate: Loader {
        id: viewLoader

        required property int index
        required property date startDate
        required property var firstDayOfMonth
        readonly property bool isNextOrCurrentItem: index >= root.currentIndex -1 && index <= root.currentIndex + 1
        readonly property bool isCurrentItem: PathView.isCurrentItem

        active: isNextOrCurrentItem
        asynchronous: !isCurrentItem
        visible: status === Loader.Ready

        sourceComponent: BasicMonthListView {
            width: root.width
            height: root.height

            openOccurrence: root.openOccurrence
            startDate: viewLoader.firstDayOfMonth
            dragDropEnabled: root.dragDropEnabled
            isCurrentItem: viewLoader.isCurrentItem
        }
    }

    Connections {
        target: Calendar.DateTimeState
        function onSelectedDateChanged() {
            root.currentIndex = root.model.moveToDate(Calendar.DateTimeState.selectedDate, root.currentItem.firstDayOfMonth, root.currentIndex);

            if (root.currentItem && root.currentItem.item) {
                root.currentItem.item.savedYScrollPos = 0;
                root.currentItem.item.moveToSelected();
            }
        }
    }
}
