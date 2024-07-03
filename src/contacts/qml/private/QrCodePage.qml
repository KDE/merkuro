// SPDX-FileCopyrightText: 2015 Martin Gräßlin <mgraesslin@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.prison 1.0 as Prison

Kirigami.Page {
    property string qrCodeData
    title: i18n("QR Code")

    contentItem: Prison.Barcode {
        id: barcodeItem
        content: qrCodeData
        barcodeType: Prison.Barcode.QRCode
    }

    QQC2.Label {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: i18n("Creating QR code failed")
        wrapMode: Text.WordWrap
        visible: barcodeItem.implicitWidth === 0 && barcodeItem.implicitHeight === 0
    }
}
