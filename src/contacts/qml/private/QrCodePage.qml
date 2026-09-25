// SPDX-FileCopyrightText: 2015 Martin Gräßlin <mgraesslin@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.prison as Prison
import org.kde.ki18n

Kirigami.Page {
    id: root

    property string qrCodeData
    title: KI18n.i18n("QR Code")

    contentItem: Prison.Barcode {
        id: barcodeItem
        content: root.qrCodeData
        barcodeType: Prison.Barcode.QRCode
    }

    QQC2.Label {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: KI18n.i18n("Creating QR code failed")
        wrapMode: Text.WordWrap
        visible: barcodeItem.implicitWidth === 0 && barcodeItem.implicitHeight === 0
    }
}
