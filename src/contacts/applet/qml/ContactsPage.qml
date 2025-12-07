// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQml
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.merkuro.contact
import org.kde.kitemmodels

PlasmaComponents3.ScrollView {
    id: scrollView
    anchors.fill: parent
    property string title: i18n("Contacts")

    property var header: PlasmaExtras.PlasmoidHeading {
        focus: true
        RowLayout {
            width: parent.width
            PlasmaExtras.SearchField {
                id: searchField
                Layout.fillWidth: true
                onTextChanged: contactsList.model.setFilterFixedString(text)
            }
        }
    }

    Keys.onPressed: {
        function goToCurrent() {
            contactsList.positionViewAtIndex(contactsList.currentIndex, ListView.Contain);
            if (contactsList.currentIndex != -1) {
                contactsList.currentItem.forceActiveFocus();
            }
        }
        if (event.modifiers & Qt.ControlModifier && event.key == Qt.Key_F) {
            toolbar.searchField.forceActiveFocus();
            toolbar.searchField.selectAll();
            event.accepted = true;
        } else if (event.key == Qt.Key_Down) {
            contactsList.incrementCurrentIndex();
            goToCurrent()
            event.accepted = true;
        } else if (event.key == Qt.Key_Up) {
            if (contactsList.currentIndex == 0) {
                contactsList.currentIndex = -1;
                searchField.forceActiveFocus();
                searchField.selectAll();
            } else {
                contactsList.decrementCurrentIndex();
                goToCurrent();
            }
            event.accepted = true;
        }
    }


    // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    contentWidth: availableWidth - contentItem.leftMargin - contentItem.rightMargin

    ItemSelectionModel {
        id: contactSelectionModel
        model: contactsList.model
    }

    contentItem: ListView {
        id: contactsList
        model: KSortFilterProxyModel {
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
                text: section.trim().length > 0 ? section : i18nc("Placeholder", "No Name")
            }
        }

        clip: true
        focus: true
        delegate: ContactListItem {
            selectionModel: contactSelectionModel
            onClicked: stack.push(Qt.resolvedUrl('./ContactPage.qml'), {
                itemId: model.itemId,
            })
        }
    }
}
