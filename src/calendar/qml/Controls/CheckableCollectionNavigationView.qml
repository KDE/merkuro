// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.calendar
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import Qt.labs.qmlmodels
import org.kde.kitemmodels

QQC2.ScrollView {
    id: root

    signal collectionCheckChanged
    signal closeParentDrawer

    readonly property Akonadi.AgentConfiguration agentConfiguration: Akonadi.AgentConfiguration {}
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
            visible: Akonadi.TagManager.tagModel.rowCount() > 0 && mode !== CalendarApplication.Contact
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
            visible: Akonadi.TagManager.tagModel.rowCount() > 0 && tagsHeadingItem.expanded && mode !== CalendarApplication.Contact

            Repeater {
                id: tagList

                model: parent.visible ? Akonadi.TagManager.tagModel : []

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

                        required property int index
                        required property var model
                        required property var decoration
                        required property var collectionId
                        required property Akonadi.collection collection
                        required property bool kDescendantExpanded
                        required property int kDescendantLevel
                        required property color collectionColor
                        required property int checkState

                        text: model.display
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

                                visible: model.checkState !== undefined
                                color: collectionSourceItem.collectionColor ?? Kirigami.Theme.highlightedTextColor
                                checked: model.checkState === 2
                                onClicked: {
                                    model.checkState = model.checkState === 0 ? 2 : 0
                                    root.collectionCheckChanged()
                                }

                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        Connections {
                            target: root.agentConfiguration

                            function onAgentProgressChanged(agentInstance: Akonadi.agentInstance): void {
                                if (!agentInstance.identifier === collectionSourceItem.collection.resource) {
                                    return;
                                }

                                loadingIndicator.visible = agentInstance.status === agentInstance.Running;
                            }
                        }

                        CalendarItemTapHandler {
                            id: tapHandler

                            onLeftClicked: collectionList.model.toggleChildren(index)

                            checkState: model.checkState
                            collection: model.collection
                            agentConfiguration: root.agentConfiguration
                            enabled: root.mode !== CalendarApplication.Contact
                            allCollectionsChecked: areAllCollectionsChecked()
                            onToggled: {
                                model.checkState = model.checkState === 0 ? 2 : 0
                                root.collectionCheckChanged()
                            }
                            onCloseParentDrawer: () => {
                                root.closeParentDrawer()
                            }

                            onShowAllCollections: (shown) => setAllCheckStatus(shown)

                            function areAllCollectionsChecked() {
                                let allChecked = true;
	                            // TODO: This is a bit of a hack, maybe this can be rewritten with QAbstractItemModel::match?
                                for (let i = 0; i < collectionList.model.rowCount(); ++i) {
                                    const index = collectionList.model.index(i, 0);
                                    const checkState = collectionList.model.data(index, Qt.CheckStateRole);
                                    if (checkState === undefined)
                                        continue;
                                    if (checkState !== Qt.Checked)
                                        allChecked = false;
                                }
                                return allChecked;
                            }

                            function setAllCheckStatus(checked) {
                                for (let i = 0; i < collectionList.model.rowCount(); ++i) {
                                    const index = collectionList.model.index(i, 0);
                                    const checkState = collectionList.model.data(index, Qt.CheckStateRole);
                                    if (checkState === undefined)
                                        continue;
                                    collectionList.model.setData(index, checked ? Qt.Checked : Qt.Unchecked, Qt.CheckStateRole);
                                }
                            }

                            Component.onCompleted: collectionList.model.dataChanged.connect(() => {
                                tapHandler.allCollectionsChecked = tapHandler.areAllCollectionsChecked()
                            });
                        }

                        DropArea {
                            id: incidenceDropArea
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionSourceItem.collection.rights & Akonadi.Collection.CanCreateCollection
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

                        required property int index
                        required property var model
                        required property var decoration
                        required property var collectionId
                        required property Akonadi.collection collection
                        required property bool kDescendantExpanded
                        required property int kDescendantLevel
                        required property color collectionColor
                        required property int checkState

                        activeFocusOnTab: true
                        text: model.display
                        enabled: !root.parentDrawerCollapsed
                        highlighted: visualFocus || incidenceDropArea.containsDrag

                        leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Kirigami.Units.smallSpacing : 0
                        leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? Math.max(0, kDescendantLevel - 2) * padding * 2 + Math.round(Kirigami.Units.smallSpacing / 2) : 0) + Kirigami.Units.smallSpacing

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

                        CalendarItemTapHandler {
                            id: tapHandler

                            checkState: model.checkState
                            collection: model.collection
                            agentConfiguration: root.agentConfiguration
                            enabled: mode !== CalendarApplication.Contact
                            onLeftClicked: {
                                Filter.collectionId = collectionId;

                                if (root.parentDrawerModal) {
                                    root.closeParentDrawer();
                                }
                            }
                            onToggled: {
                                model.checkState = model.checkState === 0 ? 2 : 0
                                root.collectionCheckChanged()
                            }
                            onCloseParentDrawer: () => {
                                root.closeParentDrawer()
                            }
                        }


                        DropArea {
                            id: incidenceDropArea
                            anchors.fill: parent
                            z: 9999
                            enabled: collectionItem.collection.rights & Akonadi.Collection.CanCreateCollection
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
