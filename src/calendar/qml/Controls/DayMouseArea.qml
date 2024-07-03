// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

MouseArea {
    id: dayMouseArea

    signal addNewIncidence(int type, date addDate)
    signal deselect

    property string defaultType: Calendar.IncidenceWrapper.TypeEvent
    property date addDate
    property double clickX
    property double clickY

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: deselect()

    onDoubleClicked: {
        if (pressedButtons & Qt.LeftButton) {
            clickX = mouseX;
            clickY = mouseY;
            addNewIncidence(defaultType, addDate);
        }
    }
    onPressed: {
        if (pressedButtons & Qt.RightButton) {
            clickX = mouseX;
            clickY = mouseY;
            dayActions.createObject(dayMouseArea, {}).open();
        }
    }

    Component {
        id: dayActions
        QQC2.Menu {
            id: actionsPopup
            y: dayMouseArea.clickY
            x: dayMouseArea.clickX

            // TODO: Add journals
            QQC2.MenuItem {
                text: i18n("New Event…")
                icon.name: "resource-calendar-insert"
                onClicked: addNewIncidence(Calendar.IncidenceWrapper.TypeEvent, dayMouseArea.addDate)
            }
            QQC2.MenuItem {
                text: i18n("New Task…")
                icon.name: "view-task-add"
                onClicked: addNewIncidence(Calendar.IncidenceWrapper.TypeTodo, dayMouseArea.addDate)
            }
        }
    }
}
