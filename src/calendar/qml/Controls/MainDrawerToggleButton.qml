// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

QQC2.ToolButton {
    property var mainDrawer: Calendar.CalendarUiUtils.appMain.mainDrawer

    visible: !Kirigami.Settings.isMobile
    icon.name: mainDrawer.collapsed ? "sidebar-expand" : "sidebar-collapse"
    onClicked: {
        if(mainDrawer.collapsed && applicationWindow().width < mainDrawer.narrowWindowWidth) { // Collapsed due to narrow window
            // We don't want to write to config as when narrow the button will only open the modal drawer
            mainDrawer.collapsed = !mainDrawer.collapsed;
        } else {
            Calendar.Config.forceCollapsedMainDrawer = !Calendar.Config.forceCollapsedMainDrawer;
            Calendar.Config.save()
        }
    }

    QQC2.ToolTip.text: mainDrawer.collapsed ? i18n("Expand Main Drawer") : i18n("Collapse Main Drawer")
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
