// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: recurringIncidenceChangePage

    signal changeAll
    signal changeThis
    signal changeThisAndFuture
    signal cancel

    // For incidence deletion
    property var incidenceWrapper
    property bool isMove: false
    property int startOffset: 0
    property int endOffset: 0
    property date occurrenceDate
    property Item caughtDelegate
    property bool allDay

    padding: Kirigami.Units.largeSpacing

    title: i18n("Change incidence date")

    function setAllDay() {
        if (allDay !== null) {
            incidenceWrapper.allDay = allDay;
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            QQC2.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: i18n("The item you are trying to change is a recurring item. Should the changes be applied only to this single occurrence, also to future items, or to all items in the recurrence?")
                wrapMode: Text.WordWrap
            }
        }

        Kirigami.ActionToolBar {
            Layout.fillWidth: true
            flat: false
            alignment: Qt.AlignRight

            actions: [
                QQC2.Action {
                    icon.name: "deletecell"
                    enabled: recurringIncidenceChangePage.incidenceWrapper !== undefined
                    shortcut: "Return"
                    text: i18n("Only This Item")
                    onTriggered: {
                        recurringIncidenceChangePage.setAllDay();
                        recurringIncidenceChangePage.changeThis();
                    }
                },
                QQC2.Action {
                    icon.name: "edit-table-delete-row"
                    text: i18n("Also Future Items")
                    onTriggered: {
                        recurringIncidenceChangePage.setAllDay();
                        recurringIncidenceChangePage.changeThisAndFuture();
                    }
                },
                QQC2.Action {
                    icon.name: "group-delete"
                    text: i18n("All Occurrences")
                    onTriggered: {
                        recurringIncidenceChangePage.setAllDay();
                        recurringIncidenceChangePage.changeAll();
                    }
                },
                QQC2.Action {
                    icon.name: "dialog-cancel"
                    text: i18n("Cancel")
                    onTriggered: recurringIncidenceChangePage.cancel()
                }
            ]
        }
    }
}

