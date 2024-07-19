// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    readonly property IncidenceEditorPage incidenceEditorPage: incidenceEditorPageInLoader

    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 32

    flags: Qt.Dialog | Qt.WindowCloseButtonHint

    Loader {
        active: !Kirigami.Settings.isMobile
        source: Qt.resolvedUrl("qrc:/GlobalMenuBar.qml")
    }

    pageStack.initialPage: IncidenceEditorPage {
        id: incidenceEditorPageInLoader

        onCancel: root.close()
        Keys.onEscapePressed: root.close()
    }

    onClosing: destroy();
}
