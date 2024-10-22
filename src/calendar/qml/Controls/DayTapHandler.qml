// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import org.kde.merkuro.utils

TapHandler {
    id: dayTapHandler

    signal addNewIncidence(int type, date addDate)
    signal deselect

    property string defaultType: Calendar.IncidenceWrapper.TypeEvent
    property date addDate
    property double clickX
    property double clickY
    property Component _dayActions: Component {
        QQC2.Menu {
            id: actionsPopup
            y: dayTapHandler.clickY
            x: dayTapHandler.clickX

            // TODO: Add journals
            QQC2.MenuItem {
                text: i18n("New Event…")
                icon.name: "resource-calendar-insert"
                onClicked: addNewIncidence(Calendar.IncidenceWrapper.TypeEvent, dayTapHandler.addDate)
            }
            QQC2.MenuItem {
                text: i18n("New Task…")
                icon.name: "view-task-add"
                onClicked: addNewIncidence(Calendar.IncidenceWrapper.TypeTodo, dayTapHandler.addDate)
            }
        }
    }

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onSingleTapped: function(eventPoint, button) {
        if (button & Qt.LeftButton) {
            deselect();
        } else if (button & Qt.RightButton) {
            const position = eventPoint.position;
            clickX = position.x;
            clickY = position.y;
            _dayActions.createObject(dayTapHandler, {}).open();
        }
    }

    onDoubleTapped: function(eventPoint, button) {
        if (button & Qt.LeftButton) {
            const position = eventPoint.position;
            clickX = position.x;
            clickY = position.y;
            IncidenceEditorManager.openNewIncidenceEditorDialog(QQC2.ApplicationWindow.window, defaultType, addDate, 0, false);
        }
    }
}
