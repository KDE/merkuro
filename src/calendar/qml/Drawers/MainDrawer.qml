// SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Templates 2.15 as T
import QtQuick.Layouts
import Qt.labs.qmlmodels
import Qt5Compat.GraphicalEffects

import org.kde.akonadi
import org.kde.merkuro.calendar
import org.kde.merkuro.components
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.kitemmodels

Kirigami.OverlayDrawer {
    id: mainDrawer

    signal calendarClicked(int collectionId)

    required property var mode
    property alias toolbar: toolbar
    property var activeTags : Filter.tags

    readonly property int collapsedWidth: menu.Layout.minimumWidth + Kirigami.Units.smallSpacing
    readonly property int expandedWidth: Kirigami.Units.gridUnit * 16
    property bool refuseModal: false
    property int prevWindowWidth: applicationWindow().width
    property int narrowWindowWidth: Kirigami.Units.gridUnit * 50

    Connections {
        target: applicationWindow()
        function onWidthChanged() {
            if(!Kirigami.Settings.isMobile) {
                const currentWindowWidthNarrow = applicationWindow().width < narrowWindowWidth;
                const prevWindowWidthNarrow = mainDrawer.prevWindowWidth < narrowWindowWidth;
                const prevCollapsed = mainDrawer.collapsed;

                // We don't want to go into modal when we are resizing the window to narrow and the drawer is collapsing
                if(currentWindowWidthNarrow && !prevWindowWidthNarrow) {
                    mainDrawer.collapsed = true;
                    refuseModal = !prevCollapsed;
                } else if (!currentWindowWidthNarrow && prevWindowWidthNarrow) {
                    if(!Config.forceCollapsedMainDrawer) {
                        mainDrawer.collapsed = false;
                    } else if(!mainDrawer.collapsed) {
                        mainDrawer.collapsed = true;
                    }
                }

                mainDrawer.prevWindowWidth = applicationWindow().width;
            }
        }
    }

    Connections {
        target: Config
        function onForceCollapsedMainDrawerChanged() {
            mainDrawer.collapsed = Config.forceCollapsedMainDrawer;
        }
    }

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    // Modal when mobile, or when the window is narrow and the drawer is expanded/being expanded
    modal: Kirigami.Settings.isMobile ||
           (applicationWindow().width < narrowWindowWidth && (!collapsed || width > collapsedWidth) && !refuseModal)
    collapsed: !Kirigami.Settings.isMobile &&
               (Config.forceCollapsedMainDrawer || applicationWindow().width < narrowWindowWidth)
    onDrawerOpenChanged: {
        // We want the drawer to be open but collapsed if we close it when it is modal on desktop
        if(!Kirigami.Settings.isMobile && !drawerOpen) {
            drawerOpen = true;
            collapsed = true;
        }
    }

    handleVisible: modal
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    width: mainDrawer.collapsed ? collapsedWidth : expandedWidth
    // Re-enable modal after the drawer has been collapsed after resizing the window to a narrow size
    onWidthChanged: if(width === collapsedWidth) refuseModal = false
    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }

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

            leftPadding: mainDrawer.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: mainDrawer.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                anchors.fill: parent

                Kirigami.Heading { // TODO: Remove once search results page complete
                    Layout.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
                    text: i18n("Calendar")

                    visible: !searchField.visible
                    opacity: mainDrawer.collapsed ? 0 : 1
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Kirigami.SearchField { // TODO: Make this open a new search results page
                    id: searchField
                    Layout.fillWidth: true
                    onTextChanged: Filter.name = text

                    visible: mainDrawer.mode & CalendarApplication.Todo
                    opacity: mainDrawer.collapsed ? 0 : 1
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Kirigami.ActionToolBar {
                    id: menu

                    Connections {
                        target: Config
                        function onShowMenubarChanged() {
                            if(!Kirigami.Settings.isMobile && !Kirigami.Settings.hasPlatformMenuBar) menu.visible = !Config.showMenubar
                        }
                    }

                    Layout.fillHeight: true
                    overflowIconName: "application-menu"

                    actions: [
                        Kirigami.Action {
                            icon.name: "edit-undo"
                            text: CalendarManager.undoRedoData.undoAvailable ?
                                i18n("Undo: ") + CalendarManager.undoRedoData.nextUndoDescription : undoAction.text
                            shortcut: undoAction.shortcut
                            enabled: CalendarManager.undoRedoData.undoAvailable
                            onTriggered: CalendarManager.undoAction();
                        },
                        Kirigami.Action {
                            icon.name: 'edit-redo'
                            text: CalendarManager.undoRedoData.redoAvailable ?
                                i18n("Redo: ") + CalendarManager.undoRedoData.nextRedoDescription : redoAction.text
                            shortcut: redoAction.shortcut
                            enabled: CalendarManager.undoRedoData.redoAvailable
                            onTriggered: CalendarManager.redoAction();
                        },
                        Kirigami.Action {
                            fromQAction: CalendarApplication.action("import_calendar")
                        },
                        Kirigami.Action {
                            text: i18n("Refresh All Calendars")
                            fromQAction: CalendarApplication.action("refresh_all")
                        },
                        Kirigami.Action {
                            fromQAction: CalendarApplication.action("toggle_menubar")
                        },
                        Kirigami.Action {
                            text: i18n("Configure")
                            icon.name: "settings-configure"

                            Kirigami.Action {
                                fromQAction: CalendarApplication.action('open_tag_manager')
                            }

                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("options_configure_keybinding")
                            }

                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("options_configure")
                            }
                        },
                        Kirigami.Action {
                            fromQAction: CalendarApplication.action('file_quit')
                            visible: !Kirigami.Settings.isMobile
                        }
                    ]

                    Component.onCompleted: {
                        for (let i in actions) {
                            let action = actions[i]
                            action.displayHint = Kirigami.DisplayHint.AlwaysHide
                        }
                        visible = !Kirigami.Settings.isMobile && !Config.showMenubar && !Kirigami.Settings.hasPlatformMenuBar
                        //HACK: Otherwise if menubar is open and then hidden hamburger refuses to appear (?)
                    }
                }
            }
        }

        QQC2.ScrollView {
            id: generalView
            implicitWidth: Kirigami.Units.gridUnit * 16
            Layout.fillWidth: true
            contentWidth: availableWidth

            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            clip: true

            QQC2.Control {
                anchors.fill: parent
                leftPadding: 0
                rightPadding: 0
                topPadding: Kirigami.Units.smallSpacing / 2
                bottomPadding: Kirigami.Units.smallSpacing / 2

                contentItem: ColumnLayout {
                    spacing: 0

                    QQC2.ButtonGroup {
                        id: pageGroup
                    }

                    Repeater {
                        id: generalActions
                        property list<Kirigami.Action> actions: [
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("open_month_view")
                                checkable: false
                                onTriggered: {
                                    monthViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("open_week_view")
                                checkable: false
                                // Override the default checked behaviour as we want this to stay highlighted
                                // in any of the hourly views, at least in desktop mode
                                checked: pageStack.currentItem && (
                                         pageStack.currentItem.mode & (CalendarApplication.Week | CalendarApplication.ThreeDay | CalendarApplication.Day))
                                onTriggered: {
                                    weekViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("open_schedule_view")
                                checkable: false
                                onTriggered: {
                                    scheduleViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action("open_todo_view")
                                checkable: false
                                onTriggered: {
                                    todoViewAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            }
                        ]
                        property list<Kirigami.Action> mobileActions: [
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action('edit_undo')
                                text: CalendarManager.undoRedoData.undoAvailable ?
                                    i18nc("@action:inmenu %1 is the name of the action getting reverted", "Undo: %1", CalendarManager.undoRedoData.nextUndoDescription) : i18n("Undo")
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action('edit_redo')
                                text: CalendarManager.undoRedoData.redoAvailable ?
                                    i18nc("@action:inmenu %1 is the name of the action getting re-applied", "Redo: %1", CalendarManager.undoRedoData.nextRedoDescription) : i18n("Redo")
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action('open_tag_manager')
                                onTriggered: {
                                    tagManagerAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            },
                            Kirigami.Action {
                                fromQAction: CalendarApplication.action('options_configure')
                                text: i18n("Settings")
                                onTriggered: {
                                    configureAction.trigger()
                                    if (mainDrawer.modal) mainDrawer.close()
                                }
                            }
                        ]
                        model: !Kirigami.Settings.isMobile ? actions : mobileActions
                        delegate: Delegates.RoundedItemDelegate {
                            required property T.Action modelData

                            QQC2.ButtonGroup.group: pageGroup

                            text: modelData.text
                            icon.name: modelData.icon.name
                            action: modelData
                            visible: modelData.visible
                            activeFocusOnTab: true
                            Layout.fillWidth: true
                        }
                    }
                }

                background: Rectangle {
                    color: Kirigami.Theme.backgroundColor
                    z: -1
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
        }

        CheckableCollectionNavigationView {
            onCollectionCheckChanged: mainDrawer.collectionCheckChanged()
            onCloseParentDrawer: mainDrawer.close()

            mode: mainDrawer.mode
            parentDrawerModal: mainDrawer.modal
            parentDrawerCollapsed: mainDrawer.collapsed

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            z: -3

            opacity: mainDrawer.collapsed ? 0 : 1

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    Delegates.RoundedItemDelegate {
        FontMetrics {
            id: textMetrics
        }

        implicitHeight: textMetrics.height + Kirigami.Units.largeSpacing * 2
        topInset: Kirigami.Units.smallSpacing
        bottomInset: Kirigami.Units.smallSpacing
        icon.name: "show-all-effects"
        text: i18n("View all tasks")
        visible: mainDrawer.mode === CalendarApplication.Todo
        Layout.fillWidth: true
        onClicked: {
            Filter.reset()
            if (mainDrawer.modal && mainDrawer.mode === CalendarApplication.Todo) {
                mainDrawer.close()
            }
        }
    }

    function collectionCheckChanged() {
        if (mode & (CalendarApplication.Event | CalendarApplication.Todo)) {
            CalendarManager.save();
        }
    }
}
