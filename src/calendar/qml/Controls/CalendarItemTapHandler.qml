// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.merkuro.calendar 1.0 as Calendar
import org.kde.akonadi 1.0 as Akonadi

TapHandler {
    id: calendarTapHandler

    property var collectionId
    property var collectionDetails
    property Akonadi.AgentConfiguration agentConfiguration

    signal leftClicked

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onTapped: (eventPoint, button) => {
        // TODO Qt6 remove
        if (!button) {
            button = eventPoint.event.button
        }
        if (button === Qt.LeftButton) {
            calendarTapHandler.leftClicked();
        } else if (!Kirigami.Settings.isMobile) {
            calendarActions.createObject(calendarTapHandler, {}).popup();
        }
    }

    onLongPressed: if (Kirigami.Settings.tabletMode) {
        calendarActions.createObject(calendarTapHandler, {}).popup();
    }

    property Loader colorDialogLoader: Loader {
        id: colorDialogLoader
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Calendar Color")
            color: calendarTapHandler.collectionDetails.color
            onAccepted: Calendar.CalendarManager.setCollectionColor(calendarTapHandler.collectionId, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }

    property Component calendarActions: Component {
        CalendarItemMenu {
            parent: calendarTapHandler.parent

            collectionId: calendarTapHandler.collectionId
            collectionDetails: calendarTapHandler.collectionDetails
            agentConfiguration: calendarTapHandler.agentConfiguration

            Component.onCompleted: if(calendarTapHandler.collectionId && !calendarTapHandler.collectionDetails) {
                calendarTapHandler.collectionDetails = Calendar.CalendarManager.getCollectionDetails(calendarTapHandler.collectionId)
            }
        }
    }
}
