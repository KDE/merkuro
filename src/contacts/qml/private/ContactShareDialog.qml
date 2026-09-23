// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.purpose as Purpose
import org.kde.ki18n

Kirigami.Page {
    id: root

    property alias index: jobView.index
    property alias model: jobView.model
    required property Kirigami.ApplicationWindow application

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    QQC2.Action {
        shortcut: "Escape"
        onTriggered: root.Kirigami.PageStack.closeDialog()
    }

    Component.onCompleted: jobView.start()

    contentItem: Purpose.JobView {
        id: jobView

        onStateChanged: {
            if (state === Purpose.PurposeJobController.Error) {
                root.application.showPassiveNotification(KI18n.i18n("Could not share contact: %1", jobView.job.errorString), "long");
                root.Kirigami.PageStack.closeDialog();
            } else if (state === Purpose.PurposeJobController.Finished) {
                root.application.showPassiveNotification(KI18n.i18n("Contact shared successfully."), "short");
                root.Kirigami.PageStack.closeDialog();
            } else if (state === Purpose.PurposeJobController.Cancelled) {
                root.Kirigami.PageStack.closeDialog();
            }
        }
    }
}
