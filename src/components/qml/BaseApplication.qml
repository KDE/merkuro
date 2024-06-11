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
import org.kde.kirigamiaddons.baseapp as BaseApp

BaseApp.ManagedWindow {
    id: root

    width: Kirigami.Units.gridUnit * 65

    minimumWidth: Kirigami.Units.gridUnit * 15
    minimumHeight: Kirigami.Units.gridUnit * 20
    onClosing: root.application.saveWindowGeometry(root)

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar

    QQC2.Action {
        id: closeOverlayAction
        shortcut: "Escape"
        onTriggered: {
            if(pageStack.layers.depth > 1) {
                pageStack.layers.pop();
                return;
            }
            if(contextDrawer && contextDrawer.visible) {
                contextDrawer.close();
                return;
            }
        }
    }

    Connections {
        target: root.application

        function onOpenTagManager() {
            const openDialogWindow = pageStack.pushDialogLayer(tagManagerPage, {
                width: root.width
            }, {
                width: Kirigami.Units.gridUnit * 30,
                height: Kirigami.Units.gridUnit * 30
            });

            openDialogWindow.Keys.escapePressed.connect(function() { openDialogWindow.closeDialog() });
        }

    }

    // TODO Qt6 use module url import instead for faster startup
    Component {
        id: tagManagerPage
        Akonadi.TagManagerPage {}
    }
}