// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.contact as Contact
import org.kde.akonadi as Akonadi
import org.kde.merkuro.components
import Qt.labs.qmlmodels
import org.kde.kitemmodels

Kirigami.OverlayDrawer {
    id: root

    signal collectionCheckChanged
    signal closeParentDrawer
    signal deleteCollection(int collectionId, var collectionDetails)

    property Akonadi.AgentConfiguration agentConfiguration: Akonadi.AgentConfiguration {}

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: !enabled || Kirigami.Settings.isMobile || (applicationWindow().width < Kirigami.Units.gridUnit * 50 && !collapsed) // Only modal when not collapsed, otherwise collapsed won't show.
    onModalChanged: drawerOpen = !modal;

    z: modal ? Math.round(position * 10000000) : 100

    drawerOpen: !Kirigami.Settings.isMobile && enabled

    handleClosedIcon.source: modal ? null : "sidebar-expand-left"
    handleOpenIcon.source: modal ? null : "sidebar-collapse-left"
    handleVisible: modal && enabled

    width: Kirigami.Units.gridUnit * 16
    Behavior on width {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: ColumnLayout {
        id: container

        spacing: 0
        clip: true

        QQC2.ToolBar {
            id: toolbar

            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.globalToolBar.preferredHeight

            leftPadding: root.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: root.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            contentItem: RowLayout {
                Kirigami.SearchField {
                    Layout.fillWidth: true

                    opacity: root.collapsed ? 0 : 1
                    onTextChanged: Contact.ContactManager.filteredContacts.setFilterFixedString(text)

                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                QQC2.ToolButton {
                    visible: !toogleMenubar.checked
                    display: QQC2.ToolButton.IconOnly
                    icon.name: "application-menu-symbolic"

                    onClicked: menu.popup();

                    QQC2.Menu {
                        id: menu
                        QQC2.MenuItem {
                            id: toogleMenubar
                            action: Kirigami.Action {
                                fromQAction: Contact.ContactApplication.action('toggle_menubar')
                            }
                        }
                    }
                }
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: collectionList

                activeFocusOnTab: true
                currentIndex: -1
                clip: true
                onActiveFocusChanged: if (currentIndex === -1 && activeFocus) {
                    currentIndex = 0;
                }

                header: Delegates.RoundedItemDelegate {
                    id: collectionHeadingItem

                    hoverEnabled: false
                    width: parent.width
                    text: i18n("Contacts")

                    contentItem: RowLayout {
                        Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            source: "view-pim-contacts"
                            isMask: true
                            color: Kirigami.Theme.disabledTextColor
                        }

                        Kirigami.Heading {
                            level: 4
                            text: collectionHeadingItem.text
                            color: Kirigami.Theme.disabledTextColor
                            Layout.fillWidth: true
                        }
                    }
                }

                model: KDescendantsProxyModel {
                    model: Contact.ContactManager.contactCollections
                }

                delegate: DelegateChooser {
                    role: 'kDescendantExpandable'

                    DelegateChoice {
                        roleValue: true

                        Delegates.RoundedItemDelegate {
                            id: collectionSourceItem

                            required property int index
                            required property var decoration
                            required property var model
                            required property var collection
                            required property int kDescendantLevel
                            required property bool kDescendantExpanded
                            required property int collectionId
                            required property var checkState
                            required property color collectionColor

                            topInset: 2 * Kirigami.Units.largeSpacing + Math.round(Kirigami.Units.smallSpacing / 2)
                            topPadding: 2 * Kirigami.Units.largeSpacing + verticalPadding
                            leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + Kirigami.Units.smallSpacing : 0
                            leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + Math.round(Kirigami.Units.smallSpacing / 2) : 0) + Kirigami.Units.smallSpacing

                            rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2  + horizontalPadding : 0) + Kirigami.Units.smallSpacing
                            rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + horizontalPadding : 0) + Math.round(Kirigami.Units.smallSpacing * 2.5)

                            text: model.display
                            highlighted: activeFocus

                            hoverEnabled: false
                            Accessible.checkable: true
                            Accessible.checked: collectionSourceItem.kDescendantExpanded

                            onClicked: collectionList.model.toggleChildren(collectionSourceItem.index)

                            contentItem: RowLayout {
                                Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                    isMask: true
                                    source: collectionSourceItem.decoration
                                    color: Kirigami.Theme.disabledTextColor
                                    Layout.leftMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                                }

                                Kirigami.Heading {
                                    text: collectionSourceItem.text
                                    elide: Text.ElideRight
                                    color: Kirigami.Theme.disabledTextColor
                                    level: 4

                                    Layout.fillWidth: true
                                }

                                QQC2.BusyIndicator {
                                    id: loadingIndicator
                                    Layout.fillHeight: true
                                    padding: 0
                                    visible: false
                                    running: visible
                                }

                                Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.small
                                    implicitHeight: Kirigami.Units.iconSizes.small
                                    source: collectionSourceItem.kDescendantExpanded ? 'arrow-up' : 'arrow-down'
                                    isMask: true
                                }

                                ColoredCheckbox {
                                    id: collectionCheckbox

                                    visible: model.checkState !== null
                                    color: collectionSourceItem.collectionColor ?? Kirigami.Theme.highlightedTextColor
                                    checked: model.checkState === 2
                                    onCheckedChanged: root.collectionCheckChanged()
                                    onClicked: {
                                        model.checkState = model.checkState === 0 ? 2 : 0
                                        root.collectionCheckChanged()
                                    }

                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            Connections {
                                target: root.agentConfiguration

                                function onAgentProgressChanged(agentData) {
                                    if (agentData.instanceId === collectionSourceItem.collection.resource &&
                                        agentData.status === Akonadi.AgentConfiguration.Running) {

                                        loadingIndicator.visible = true;
                                    } else if (agentData.instanceId === collectionSourceItem.collection.resource) {
                                        loadingIndicator.visible = false;
                                    }
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: false

                        Delegates.RoundedItemDelegate {
                            id: collectionItem

                            required property int index
                            required property var decoration
                            required property var model
                            required property var collection
                            required property int kDescendantLevel
                            required property bool kDescendantExpanded
                            required property int collectionId
                            required property var checkState
                            required property color collectionColor

                            text: model.display
                            enabled: !root.drawerCollapsed
                            highlighted: activeFocus

                            leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Kirigami.Units.smallSpacing : 0
                            leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Math.round(Kirigami.Units.smallSpacing / 2) : 0) + Kirigami.Units.smallSpacing

                            rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2  + horizontalPadding : 0) + Kirigami.Units.smallSpacing
                            rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + horizontalPadding : 0) + Math.round(Kirigami.Units.smallSpacing * 2.5)

                            Accessible.checkable: true
                            Accessible.checked: model.checkState === 2
                            Accessible.onToggleAction: clicked()

                            contentItem: RowLayout {
                                Kirigami.Icon {
                                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                    source: collectionItem.decoration
                                    Layout.leftMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                                }

                                QQC2.Label {
                                    text: collectionItem.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                ColoredCheckbox {
                                    id: collectionCheckbox

                                    Layout.alignment: Qt.AlignVCenter
                                    visible: model.checkState !== null
                                    color: collectionItem.collectionColor
                                    checked: model.checkState === 2
                                    onCheckedChanged: root.collectionCheckChanged()
                                    activeFocusOnTab: false
                                    onClicked: {
                                        model.checkState = model.checkState === 0 ? 2 : 0
                                        root.collectionCheckChanged()
                                    }
                                }
                            }

                            onClicked: {
                                collectionItem.model.checkState = collectionItem.checkState === 0 ? 2 : 0
                                root.collectionCheckChanged()
                            }
                        }
                    }
                }
            }
        }
    }
}
