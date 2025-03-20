// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.merkuro.components
import org.kde.akonadi as Akonadi
import org.kde.kirigamiaddons.statefulapp as StatefulApp

StatefulApp.StatefulWindow {
    id: root

    required property Component menubarComponent

    width: Kirigami.Units.gridUnit * 65
    windowName: 'Main'

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar

    menuBar: Loader {
        active: !Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile && root.application.menubarVisible && root.pageStack.currentItem

        height: active ? implicitHeight : 0
        sourceComponent: root.menubarComponent
        onItemChanged: if (item) {
            item.Kirigami.Theme.colorSet = Kirigami.Theme.Header;
        }
    }

    property Item hoverLinkIndicator: QQC2.Control {
        parent: root.overlay.parent
        property alias text: linkText.text
        opacity: text.length > 0 ? 1 : 0

        z: 9999
        x: 0
        y: parent.height - implicitHeight
        contentItem: QQC2.Label {
            id: linkText
        }
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        background: Rectangle {
             color: Kirigami.Theme.backgroundColor
        }
    }

    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"
        onTriggered: {
            if(root.pageStack.layers.depth > 1) {
                root.pageStack.layers.pop();
                return;
            }
            if(root.contextDrawer?.visible) {
                root.contextDrawer.close();
                return;
            }
        }
    }

    Connections {
        target: root.application

        function onOpenTagManager() {
            const openDialogWindow = root.pageStack.pushDialogLayer(Qt.createComponent('org.kde.akonadi', 'TagManagerPage'), {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

    }
}
