// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar

Components.MessageDialog {
    id: deletePage

    signal addException(date exceptionDate, var incidenceWrapper)
    signal addRecurrenceEndDate(date endDate, var incidenceWrapper)
    signal deleteIncidence(var incidencePtr)
    signal deleteIncidenceWithChildren(var incidencePtr)
    signal cancel

    // For incidence deletion
    property var incidenceWrapper
    property bool incidenceHasChildren: incidenceWrapper !== undefined ? CalendarManager.hasChildren(incidenceWrapper.incidencePtr) : false
    property date deleteDate

    modal: true
    focus: true

    dialogType: Components.MessageDialog.Warning

    title: incidenceWrapper && incidenceWrapper.incidenceTypeStr ?
        i18nc("%1 is the type of the incidence (e.g event, todo, journal entry)", "Delete %1", incidenceWrapper.incidenceTypeStr) :
        i18n("Delete")

    Controls.Action {
        id: deleteAction
        enabled: incidenceWrapper !== undefined
        shortcut: "Return"
        onTriggered: {
            incidenceWrapper.recurrenceData.type > 0 ?
                addException(deleteDate, incidenceWrapper) :
                deleteIncidence(incidenceWrapper.incidencePtr);
        }
    }

    Controls.Label {
        Layout.fillWidth: true
        horizontalAlignment: Qt.AlignHCenter
        text: if(incidenceWrapper.recurrenceData.type === 0 && !deletePage.incidenceHasChildren) {
            return i18n("Do you want to delete item: \"%1\"?", incidenceWrapper.summary)
        } else if(incidenceWrapper.recurrenceData.type === 0 && deletePage.incidenceHasChildren) {
            return i18n("Item \"%1\" has sub-items. Do you want to delete all related items, or just the currently selected item?", incidenceWrapper.summary)
        } else if (incidenceWrapper.recurrenceData.type > 0 && deletePage.incidenceHasChildren) {
            return i18n("The calendar item \"%1\" recurs over multiple dates. This item also has sub-items.\n\nDo you want to delete the selected occurrence on %2, also future occurrences, or all of its occurrences?\n\nDeleting all will also delete sub-items!", incidenceWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
        } else if (incidenceWrapper.recurrenceData.type > 0) {
            return i18n("The calendar item \"%1\" recurs over multiple dates. Do you want to delete the selected occurrence on %2, also future occurrences, or all of its occurrences?", incidenceWrapper.summary, deleteDate.toLocaleDateString(Qt.locale()))
        }
        wrapMode: Text.Wrap
    }

    footer: GridLayout {
        id: footerLayout
        property bool verticalLayout: deletePage.incidenceHasChildren || incidenceWrapper.recurrenceData.type > 0

        columnSpacing: Kirigami.Units.mediumSpacing
        rowSpacing: Kirigami.Units.mediumSpacing
        columns: verticalLayout ? 1 : 3

        Controls.Button {
            icon.name: "deletecell"
            text: i18n("Only Delete Current")
            visible: incidenceWrapper.recurrenceData.type > 0
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            onClicked: addException(deleteDate, incidenceWrapper)
        }

        Controls.Button {
            icon.name: "edit-table-delete-row"
            text: i18n("Also Delete Future")
            visible: incidenceWrapper.recurrenceData.type > 0
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            onClicked: {
                // We want to include the delete date in the deletion
                // Setting the last recurrence day is not inclusive
                // (i.e. occurrence on that day is not deleted)
                let dateBeforeDeleteDate = new Date(deleteDate);
                dateBeforeDeleteDate.setDate(deleteDate.getDate() - 1);
                addRecurrenceEndDate(dateBeforeDeleteDate, incidenceWrapper)
            }
        }

        Controls.Button {
            icon.name: "group-delete"
            text: i18n("Delete Only This")
            visible: deletePage.incidenceHasChildren && incidenceWrapper.recurrenceData.type === 0
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            onClicked: deleteIncidence(incidenceWrapper.incidencePtr)
        }

        Item {
            visible: !footerLayout.verticalLayout
            Layout.fillWidth: true
        }

        Controls.Button {
            icon.name: "delete"
            text: deletePage.incidenceHasChildren || incidenceWrapper.recurrenceData.type > 0 ? i18n("Delete All") : i18n("Delete")
            Layout.fillWidth: footerLayout.verticalLayout
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: footerLayout.verticalLayout ? Kirigami.Units.largeSpacing * 2 : 0
            Layout.bottomMargin: footerLayout.verticalLayout ? 0 : Kirigami.Units.largeSpacing * 2
            onClicked: deletePage.incidenceHasChildren ? deleteIncidenceWithChildren(incidenceWrapper.incidencePtr) : deleteIncidence(incidenceWrapper.incidencePtr)
        }

        Controls.Button {
            icon.name: "dialog-cancel"
            text: i18n("Cancel")
            Layout.fillWidth: footerLayout.verticalLayout
            Layout.leftMargin: footerLayout.verticalLayout ? Kirigami.Units.largeSpacing * 2 : 0
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            Layout.bottomMargin: Kirigami.Units.largeSpacing * 2
            onClicked: cancel()
        }
    }
}
