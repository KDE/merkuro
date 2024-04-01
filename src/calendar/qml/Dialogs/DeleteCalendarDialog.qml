// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar

Components.MessageDialog {
    id: root

    signal deleteCollection(int collectionId)
    signal cancel

    // For calendar deletion
    property int collectionId
    property var collectionDetails

    title: collectionId ? i18nc("@title:window", "Delete calendar") : i18nc("@title:window", "Delete")
    dialogType: Components.MessageDialog.Warning

    onRejected: root.close()
    onAccepted: CalendarManager.deleteCollection(root.collectionId)

    QQC2.Action {
        id: deleteAction
        enabled: collectionId !== undefined
        shortcut: "Return"
        onTriggered: root.accepted();
    }

    contentItem: RowLayout {
        ColumnLayout {
            Layout.fillWidth: true

            QQC2.Label {
                Layout.fillWidth: true
                text: if (collectionDetails) {
                    i18n("Do you want to delete the calendar: \"%1\"?", collectionDetails.displayName)
                }
                wrapMode: Text.WordWrap
            }

            QQC2.Label {
                text: i18n("You won't be able to revert this action")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        leftPadding: Kirigami.Units.largeSpacing * 2
        rightPadding: Kirigami.Units.largeSpacing * 2
        bottomPadding: Kirigami.Units.largeSpacing * 2
        topPadding: Kirigami.Units.largeSpacing

        QQC2.Button {
            text: i18n("Cancel")
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
        }
        QQC2.Button {
            text: i18n("Delete calendar")
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }
    }
}

