// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.16 as Kirigami
import org.kde.kirigamiaddons.delegates 1.0 as Delegates
import org.kde.merkuro.calendar 1.0
import org.kde.merkuro.contact 1.0
import org.kde.merkuro.mail 1.0
import org.kde.akonadi 1.0
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0

QQC2.ScrollView {
    id: root

    signal collectionCheckChanged
    signal closeParentDrawer
    signal deleteCollection(int collectionId, var collectionDetails)

    readonly property AgentConfiguration agentConfiguration: AgentConfiguration {}
    readonly property var activeTags: Filter.tags

    property var mode: CalendarApplication.Event
    property bool parentDrawerModal: false
    property bool parentDrawerCollapsed: false

    implicitWidth: Kirigami.Units.gridUnit * 16
    contentWidth: availableWidth

    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Delegates.RoundedItemDelegate {
            id: tagsHeadingItem

            property bool expanded: Config.tagsSectionExpanded

            Layout.topMargin: Kirigami.Units.largeSpacing
            hoverEnabled: false
            visible: TagManager.tagModel.rowCount() > 0 && mode !== CalendarApplication.Contact
            Accessible.name: tagsHeadingItem.expanded ? i18nc('Accessible description of dropdown menu', 'Tags, Expanded') : i18nc('Accessible description of dropdown menu', 'Tags, Collapsed')

            Kirigami.Heading {
                id: headingSizeCalculator
                level: 4
            }

            activeFocusOnTab: true
            highlighted: visualFocus
            text: i18n("Tags")

            onClicked: {
                Config.tagsSectionExpanded = !Config.tagsSectionExpanded;
                Config.save();
            }

            contentItem: RowLayout {
                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    isMask: true
                    source: "action-rss_tag"
                    color: Kirigami.Theme.disabledTextColor
                }

                QQC2.Label {
                    font.pointSize: headingSizeCalculator.font.pointSize
                    text: tagsHeadingItem.text
                    color: Kirigami.Theme.disabledTextColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    source: tagsHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                    isMask: true
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                }
            }

            Layout.bottomMargin: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
        }

        Flow {
            id: tagFlow
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Settings.isMobile ?
                Kirigami.Units.largeSpacing * 2 :
                Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Settings.isMobile ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing
            visible: TagManager.tagModel.rowCount() > 0 && tagsHeadingItem.expanded && mode !== CalendarApplication.Contact

            Repeater {
                id: tagList

                model: parent.visible ? TagManager.tagModel : []

                delegate: Tag {
                    implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                    text: model.display
                    showAction: false
                    activeFocusOnTab: true
                    backgroundColor: root.activeTags.includes(model.display) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    enabled: !root.parentDrawerCollapsed
                    onClicked: Filter.toggleFilterTag(model.display)
                }
            }
        }

        Delegates.RoundedItemDelegate {
            id: collectionHeadingItem

            readonly property bool expanded: Config.collectionsSectionExpanded

            onClicked: {
                Config.collectionsSectionExpanded = !Config.collectionsSectionExpanded;
                Config.save();
            }

            hoverEnabled: false
            text: i18n("Calendars")
            Accessible.name: collectionHeadingItem.expanded ? i18nc('Accessible description of dropdown menu', 'Calendars, Expanded') : i18nc('Accessible description of dropdown menu', 'Calendars, Collapsed')
            activeFocusOnTab: true

            contentItem: RowLayout {
                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    source: "view-calendar"
                    isMask: true
                    color: Kirigami.Theme.disabledTextColor
                }

                QQC2.Label {
                    font.pointSize: headingSizeCalculator.font.pointSize
                    text: collectionHeadingItem.text
                    elide: Text.ElideRight
                    color: Kirigami.Theme.disabledTextColor
                    Layout.fillWidth: true
                }

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    source: collectionHeadingItem.expanded ? 'arrow-up' : 'arrow-down'
                    isMask: true
                    Layout.rightMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
        }

        Repeater {
            id: collectionList

            property var collectionModel: KDescendantsProxyModel {
                model: {
                    switch(root.mode) {
                    case CalendarApplication.Todo:
                        return CalendarManager.todoCollections;
                    default:
                        return CalendarManager.viewCollections;
                    }
                }
            }

            model: collectionHeadingItem.expanded ? collectionModel : []

            delegate: DelegateChooser {
                role: 'kDescendantExpandable'
                DelegateChoice {
                    roleValue: true

                    Delegates.RoundedItemDelegate {
                        id: collectionSourceItem
                        // FIXME label: model.display
                        highlighted: visualFocus || incidenceDropArea.containsDrag
                        activeFocusOnTab: true

                        leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + Kirigami.Units.smallSpacing : 0
                        leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + Math.round(Kirigami.Units.smallSpacing / 2) : 0) + Kirigami.Units.smallSpacing

                        rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2  + horizontalPadding : 0) + Kirigami.Units.smallSpacing
                        rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? (kDescendantLevel - 1) * padding * 2 + horizontalPadding : 0) + Math.round(Kirigami.Units.smallSpacing * 2.5)

                        hoverEnabled: false
                        enabled: !root.parentDrawerCollapsed

                        Layout.topMargin: 2 * Kirigami.Units.largeSpacing
                        Layout.fillWidth: true

                        Accessible.checkable: true
                        Accessible.checked: collectionSourceItem.kDescendantExpanded

                        contentItem: RowLayout {
                            Kirigami.Icon {
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                isMask: true
                                source: collectionSourceItem.decoration
                                color: Kirigami.Theme.disabledTextColor
                                Layout.leftMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                            }

                            QQC2.Label {
                                text: collectionSourceItem.text
                                elide: Text.ElideRight
                                font.pointSize: headingSizeCalculator.font.pointSize
                                color: Kirigami.Theme.disabledTextColor

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

                                visible: model.checkState != null
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
                            property var collectionDetails: CalendarManager.getCollectionDetails(collectionSourceItem.collectionId)

                            function onAgentProgressChanged(agentData) {
                                if(agentData.instanceId === collectionDetails.resource &&
                                    agentData.status === AgentConfiguration.Running) {

                                    loadingIndicator.visible = true;
                                } else if (agentData.instanceId === collectionDetails.resource) {
                                    loadingIndicator.visible = false;
                                }
                            }
                        }

                        CalendarItemTapHandler {
                            id: tapHandler

                            onLeftClicked: collectionList.model.toggleChildren(index)

                            collectionId: model.collectionId
                            collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                            agentConfiguration: root.agentConfiguration
                            enabled: root.mode !== CalendarApplication.Contact
                        }

                        DropArea {
                            id: incidenceDropArea
                            property var collectionDetails: CalendarManager.getCollectionDetails(model.collectionId)
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionDetails.canCreate
                            onDropped: if(drop.source.objectName === "taskDelegate") {
                                CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, model.collectionId);

                                const pos = mapToItem(applicationWindow().contentItem, x, y);
                                drop.source.caughtX = pos.x;
                                drop.source.caughtY = pos.y;
                                drop.source.caught = true;
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: false

                    Delegates.RoundedItemDelegate {
                        id: collectionItem
                        // FIXME label: model.display
                        // FIXME labelItem.color: Kirigami.Theme.textColor
                        leftPadding: Kirigami.Settings.isMobile ?
                            (Kirigami.Units.largeSpacing * 2 * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1)) :
                            (Kirigami.Units.largeSpacing * model.kDescendantLevel) + (Kirigami.Units.iconSizes.smallMedium * (model.kDescendantLevel - 1))
                        // FIXME separatorVisible: false
                        enabled: !root.parentDrawerCollapsed
                        highlighted: visualFocus || incidenceDropArea.containsDrag

                        leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Kirigami.Units.smallSpacing : 0
                        //leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Math.round(Kirigami.Units.smallSpacing / 2) : 0) + Kirigami.Units.smallSpacing

                        rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2  + horizontalPadding : 0) + Kirigami.Units.smallSpacing
                        rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + horizontalPadding : 0) + Math.round(Kirigami.Units.smallSpacing * 2.5)

                        Layout.fillWidth: true

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
                                visible: model.checkState != null
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

                        CalendarItemTapHandler {
                            collectionId: model.collectionId
                            collectionDetails: CalendarManager.getCollectionDetails(collectionId)
                            agentConfiguration: root.agentConfiguration
                            enabled: mode !== CalendarApplication.Contact
                            onDeleteCalendar: root.deleteCollection(collectionId, collectionDetails)
                            onLeftClicked: {
                                Filter.collectionId = collectionId;
                                model.checkState = model.checkState === 0 ? 2 : 0;
                                root.collectionCheckChanged();
                                if (root.parentDrawerModal) {
                                    root.closeParentDrawer();
                                }
                            }
                        }

                        DropArea {
                            id: incidenceDropArea
                            property var collectionDetails: CalendarManager.getCollectionDetails(model.collectionId)
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionDetails.canCreate
                            onDropped: if(drop.source.objectName === "taskDelegate") {
                                CalendarManager.changeIncidenceCollection(drop.source.incidencePtr, model.collectionId);

                                const pos = mapToItem(applicationWindow().contentItem, x, y);
                                drop.source.caughtX = pos.x;
                                drop.source.caughtY = pos.y;
                                drop.source.caught = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
