// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar
import org.kde.akonadi as Akonadi

TapHandler {
    id: root

    required property var checkState
    required property Akonadi.collection collection
    property Akonadi.AgentConfiguration agentConfiguration
    property bool allCollectionsChecked

    signal leftClicked
    signal closeParentDrawer
    signal toggled
    signal showAllCollections(bool shown)

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onTapped: (eventPoint, button) => {
        if (button === Qt.LeftButton && !Kirigami.Settings.isMobile) {
            root.leftClicked();
        } else {
            if (Kirigami.Settings.isMobile) {
                root.closeParentDrawer();
            }
            const item = calendarActions.createObject(applicationWindow(), {});
            item.popup(applicationWindow());
        }
    }

    property Component calendarActions: Calendar.CalendarItemMenu {
        parent: root.parent

        checkState: root.checkState
        collectionId: root.collection.id
        collectionDetails: Calendar.CalendarManager.getCollectionDetails(root.collection.id)
        agentConfiguration: root.agentConfiguration
        allCollectionsChecked: root.allCollectionsChecked
        onToggled: root.toggled()
        onShowAllCollections: (shown) => root.showAllCollections(shown)
    }
}
