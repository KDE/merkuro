// SPDX-FileCopyrightText: 2019 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQml.Models
import org.kde.merkuro.mail
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property string content
    property bool autoLoadImages: false

    property string searchString
    property int contentHeight: childrenRect.height

    spacing: Kirigami.Units.smallSpacing

    Kirigami.InlineMessage {
        id: signedButton
        Layout.fillWidth: true
        Layout.maximumWidth: parent.width
        visible: true
        text: i18n("This mail contains an invitation")
    }
}
