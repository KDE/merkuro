// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.merkuro.calendar

QQC2.Dialog {
    id: root

    signal deleteCollection(int collectionId)
    signal cancel

    // For calendar deletion
    property int collectionId
    property var collectionDetails

    x: Math.round((parent.width - width) / 2)
    y: Math.round(parent.height / 3)

    width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 30)

    title: collectionId ? i18nc("@title:window", "Delete calendar") : i18nc("@title:window", "Delete")

    modal: true
    focus: true

    onRejected: root.close()
    onAccepted: CalendarManager.deleteCollection(root.collectionId)

    background: Components.DialogRoundedBackground {}

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

        Kirigami.Icon {
            source: "data-warning"
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
        }
    }

    footer: QQC2.DialogButtonBox {
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

