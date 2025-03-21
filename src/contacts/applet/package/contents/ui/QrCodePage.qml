// SPDX-FileCopyrightText: 2015 Martin Gräßlin <mgraesslin@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQml
import QtQuick.Layouts
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kquickcontrolsaddons
import org.kde.merkuro.contact
import org.kde.prison as Prison
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: barcodeView

    property string qrCodeData
    property string title: i18n("QR Code")

    Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
            stack.pop()
            event.accepted = true;
        }
    }
    property var header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            PlasmaComponents3.Button {
                Layout.fillWidth: true
                icon.name: "go-previous-view"
                text: i18n("Return to Contact")
                onClicked: stack.pop()
            }

            Component {
                id: menuItemComponent
                PlasmaComponents3.MenuItem { }
            }

            PlasmaComponents3.Menu {
                id: menu
                x: configureButton.x
                y: configureButton.y + configureButton.height
                onClosed: configureButton.checked = false

                Component.onCompleted: {
                    [
                        {text: i18n("QR Code"), type: Prison.Barcode.QRCode},
                        {text: i18n("Data Matrix"), type: Prison.Barcode.DataMatrix},
                        {text: i18nc("Aztec barcode", "Aztec"), type: Prison.Barcode.Aztec}
                    ].forEach((item) => {
                        let menuItem = menuItemComponent.createObject(menu, {
                            text: item.text,
                            checkable: true,
                            checked: Qt.binding(() => {
                                return barcodeItem.barcodeType === item.type;
                            })
                        });
                        menuItem.clicked.connect(() => {
                            barcodeItem.barcodeType = item.type;
                            Plasmoid.configuration.barcodeType = item.type;
                        });
                        menu.addItem(menuItem);
                    });
                }
            }
            PlasmaComponents3.ToolButton {
                id: configureButton
                checkable: true
                icon.name: "configure"
                onClicked: menu.open()

                PlasmaComponents3.ToolTip {
                    text: i18n("Change the QR code type")
                }
            }
        }
    }
    Item {
        Layout.fillWidth: parent
        Layout.fillHeight: parent
        Layout.topMargin: Kirigami.Units.smallSpacing

        Prison.Barcode {
            id: barcodeItem
            readonly property bool valid: implicitWidth > 0 && implicitHeight > 0 && implicitWidth <= width && implicitHeight <= height
            content: qrCodeData
            anchors.fill: parent
            barcodeType: Plasmoid.configuration.barcodeType
            // Cannot set visible to false as we need it to re-render when changing its size
            opacity: valid ? 1 : 0
        }

        PlasmaComponents3.Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: i18n("Creating QR code failed")
            wrapMode: Text.WordWrap
            visible: barcodeItem.implicitWidth === 0 && barcodeItem.implicitHeight === 0
        }

        PlasmaComponents3.Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: i18n("The QR code is too large to be displayed")
            wrapMode: Text.WordWrap
            visible: barcodeItem.implicitWidth > barcodeItem.width || barcodeItem.implicitHeight > barcodeItem.height
        }
    }
}
