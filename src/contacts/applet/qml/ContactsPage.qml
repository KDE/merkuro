// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.merkuro.contact
import org.kde.ki18n

PlasmaComponents3.ScrollView {
    id: scrollView
    anchors.fill: parent
    property string title: KI18n.i18n("Contacts")
    readonly property QQC2.StackView pageStack: scrollView.QQC2.StackView.view

    property var header: PlasmaExtras.PlasmoidHeading {
        focus: true
        RowLayout {
            width: parent.width
            PlasmaExtras.SearchField {
                id: searchField
                objectName: "contactSearchField"
                Layout.fillWidth: true
                onTextChanged: contactsList.model.setFilterFixedString(text)
            }
        }
    }

    function goToCurrent(): void {
        contactsList.positionViewAtIndex(contactsList.currentIndex, ListView.Contain);
        if (contactsList.currentItem) {
            contactsList.currentItem.forceActiveFocus();
        }
    }

    Keys.onPressed: function(event: KeyEvent): void {
        if (event.modifiers & Qt.ControlModifier && event.key == Qt.Key_F) {
            searchField.forceActiveFocus();
            searchField.selectAll();
            event.accepted = true;
        } else if (event.key == Qt.Key_Down) {
            contactsList.incrementCurrentIndex();
            scrollView.goToCurrent()
            event.accepted = true;
        } else if (event.key == Qt.Key_Up) {
            if (contactsList.currentIndex == 0) {
                contactsList.currentIndex = -1;
                searchField.forceActiveFocus();
                searchField.selectAll();
            } else {
                contactsList.decrementCurrentIndex();
                scrollView.goToCurrent();
            }
            event.accepted = true;
        }
    }


    // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    contentWidth: availableWidth

    ItemSelectionModel {
        id: contactSelectionModel
        model: contactsList.model
    }

    contentItem: ListView {
        id: contactsList
        objectName: "contactsList"
        model: ContactListProxyModel {
            filterCaseSensitivity: Qt.CaseInsensitive
            sourceModel: ContactsModel {}
        }
        boundsBehavior: Flickable.StopAtBounds
        spacing: Kirigami.Units.smallSpacing
        activeFocusOnTab: true
        reuseItems: true

        section {
            property: "display"
            criteria: ViewSection.FirstCharacter
            delegate: Kirigami.ListSectionHeader {
                required property string section
                text: section.trim().length > 0 ? section : KI18n.i18nc("Placeholder", "No Name")
            }
        }

        clip: true
        focus: true
        delegate: ContactListItem {
            id: contactDelegate

            selectionModel: contactSelectionModel
            onClicked: scrollView.pageStack.push(Qt.resolvedUrl('./ContactPage.qml'), {
                itemId: contactDelegate.itemId,
            })
        }
    }
}
