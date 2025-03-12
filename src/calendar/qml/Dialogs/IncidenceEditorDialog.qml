// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.merkuro.calendar as Calendar

Kirigami.ApplicationWindow {
    id: root

    readonly property Calendar.IncidenceEditorPage incidenceEditorPage: incidenceEditorPageInLoader

    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 32

    flags: Qt.Dialog | Qt.WindowCloseButtonHint

    Loader {
        active: !Kirigami.Settings.isMobile
        sourceComponent: Qt.createComponent("org.kde.merkuro.calendar", "GlobalMenuBar")
    }

    pageStack.initialPage: Calendar.IncidenceEditorPage {
        id: incidenceEditorPageInLoader

        onCancel: root.close()
        Keys.onEscapePressed: root.close()
    }

    onClosing: destroy();
}
