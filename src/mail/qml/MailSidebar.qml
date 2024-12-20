// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Qt.labs.qmlmodels
import org.kde.kitemmodels
import org.kde.akonadi as Akonadi
import org.kde.merkuro.mail
import org.kde.merkuro.components

import './mailboxselector'

Kirigami.OverlayDrawer {
    id: root

    property Akonadi.AgentConfiguration agentConfiguration: Akonadi.AgentConfiguration {}

    signal search(string searchString)

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
                    onEditingFinished: root.search(text)
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        QQC2.ScrollView {
            id: folderListView

            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: availableWidth

            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            contentItem: MailBoxList {
                clip: true
            }

            property Kirigami.PagePool pagePool: Kirigami.PagePool {
                id: pagePool
            }

            function getPage(name: string): Kirigami.Page {
                switch (name) {
                case "FolderView":
                    return pagePool.loadPage(Qt.resolvedUrl("./FolderView.qml"))
                case "MailBoxListPage":
                    return pagePool.loadPage(Qt.resolvedUrl("./mailboxselector/MailBoxListPage.qml"))
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: progressStatusBar.working

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Akonadi.ProgressStatusBar {
                id: progressStatusBar
                Layout.fillWidth: true
            }
        }
    }
}
