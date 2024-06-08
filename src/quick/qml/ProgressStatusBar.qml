// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.akonadi as Akonadi

RowLayout {
    id: root

    property alias working: progressModel.working

    Akonadi.ProgressModel {
        id: progressModel
    }

    QQC2.ProgressBar {
        id: progressBar

        Layout.fillWidth: true

        from: 0
        to: 100
        value: progressModel.progress
        indeterminate: progressModel.indeterminate
    }
}