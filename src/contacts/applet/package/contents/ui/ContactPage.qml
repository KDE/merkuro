// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.merkuro.contact

PlasmaComponents3.ScrollView {
    id: root

    property int itemId
    topPadding: 0

    property string title: addressee.formattedName

    property AddresseeWrapper addressee: AddresseeWrapper {
        addresseeItem: ContactManager.getItem(root.itemId)
    }
    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    function callNumber(number) {
        Qt.openUrlExternally("tel:" + number)
    }

    function sendSms(number) {
        Qt.openUrlExternally("sms:" + number)
    }

    Keys.onPressed: if (event.key === Qt.Key_Escape) {
        stack.pop()
        event.accepted = true;
    }

    property var header: PlasmaExtras.PlasmoidHeading {
        Component {
            id: menuItemComponent
            PlasmaComponents3.MenuItem { }
        }
        RowLayout {
            width: parent.width

            PlasmaComponents3.Button {
                icon.name: "go-previous-view"
                text: i18n("Return to Contact List")
                onClicked: stack.pop()
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                id: configureButtonCall
                Accessible.name: i18n("Call")
                PlasmaComponents3.ToolTip { text: i18n("Call") }
                icon.name: "call-start"
                visible: addressee.phoneNumbers.length > 0
                onClicked: {
                    const model = addressee.phoneNumbers;

                    if (model.length === 1) {
                        page.callNumber(model[0].normalizedNumber);
                    } else {
                        if (menuCall.count == 0) {
                            model.forEach((item) => {
                                let menuItem = menuItemComponent.createObject(menuCall, {
                                    text: i18n("%1 (%2)", item.typeLabel, item.number)
                                });
                                menuItem.clicked.connect(() => {
                                    callNumber(item.number);
                                });
                                menuCall.addItem(menuItem);
                            });
                        }
                        menuCall.open();
                    }
                }
                PlasmaComponents3.Menu {
                    id: menuCall
                    y: configureButtonCall.height
                }
            }

            PlasmaComponents3.ToolButton {
                id: configureButtonSms
                Accessible.name: i18n("Send SMS")
                PlasmaComponents3.ToolTip { text: i18n("Send SMS") }
                icon.name: "mail-message"
                visible: addressee.phoneNumbers.length > 0
                onClicked: {
                    const model = addressee.phoneNumbers;

                    if (addressee.phoneNumbers.length === 1) {
                        sendSms(model[0].normalizedNumber);
                    } else {
                        if (menuSms.count == 0) {
                            model.forEach((item) => {
                                let menuItem = menuItemComponent.createObject(menuSms, {
                                    text: i18n("%1 (%2)", item.typeLabel, item.number)
                                });
                                menuItem.clicked.connect(() => {
                                    sendSms(item.number);
                                });
                                menuSms.addItem(menuItem);
                            });
                        }
                        menuSms.open();
                    }
                }
                PlasmaComponents3.Menu {
                    id: menuSms
                    y: configureButtonSms.height
                }
            }

            PlasmaComponents3.ToolButton {
                Accessible.name: i18n("Send Email")
                PlasmaComponents3.ToolTip { text: i18n("Send Email") }
                icon.name: "mail-message"
                visible: addressee.preferredEmail.length > 0
                onClicked: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
            }

            PlasmaComponents3.ToolButton {
                icon.name: 'view-barcode-qr'
                Accessible.name: i18n("Show QR Code")
                PlasmaComponents3.ToolTip { text: i18n("Show QR Code") }
                onClicked: stack.push(Qt.resolvedUrl('./QrCodePage.qml'), {
                    qrCodeData: addressee.qrCodeData(),
                })
            }
        }
    }

    contentItem: Flickable {
        contentHeight: layout.implicitHeight
        ColumnLayout {
            id: layout
            width: parent.width
            spacing: 0
            Header {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8

                source: addressee.photo.isIntern ? addressee.photo.data : addressee.photo.url
                backgroundSource: Qt.resolvedUrl("../resources/fallbackBackground.png")

                contentItems: PlasmaExtras.Heading {
                    text: addressee.formattedName
                    color: "#fcfcfc"
                    level: 2
                }
            }

            PlasmaComponents3.Label {
                visible: addressee.nickName !== ""
                text: i18n("Nickname: %1", addressee.nickName)
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            PlasmaComponents3.Label {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                visible: text !== i18n("Birthday:") + ' '
                text: if (addressee.birthday.getFullYear() === 0) {
                    return Qt.formatDate(addressee.birthday, i18nc("Day month format", "dd.MM."))
                } else {
                    return i18n("Birthday:") + ' ' + addressee.birthday.toLocaleDateString()
                }
            }

            PlasmaExtras.Heading {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                visible: addressesRepeater.count > 0
                text: i18np("Address", "Addresses", addressesRepeater.count)
                level: 4
            }

            Repeater {
                id: addressesRepeater
                model: addressee.addressesModel
                PlasmaComponents3.Label {
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    visible: text.lenght !== 0
                    text: (model.typeLabel ? i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", model.typeLabel) : '') + ' ' + model.formattedAddress
                }
            }

            PlasmaExtras.Heading {
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: emailRepeater.count > 0
                text: i18np("Email Address", "Email Addresses", emailRepeater.count)
                level: 4
            }

            Repeater {
                id: emailRepeater
                model: addressee.emailModel
                PlasmaComponents3.Label {
                    visible: text !== ""
                    text: `${model.type} <a href="mailto:${model.display}">${model.display}</a>`
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    PlasmaComponents3.ToolTip { text: i18n("Send Email") }
                    onLinkActivated: Qt.openUrlExternally(link)
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(`mailto:${model.display}`)
                    }
                }
            }

            PlasmaExtras.Heading {
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: phoneRepeater.count > 0
                text: i18np("Phone number", "Phone numbers", phoneRepeater.count)
                level: 4
            }

            Repeater {
                id: phoneRepeater
                model: addressee.phoneModel
                PlasmaComponents3.Label {
                    visible: text !== ""
                    text: i18n("%1:", model.type) + ` <a href="tel:${model.display}">${model.display}</a>`
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    PlasmaComponents3.ToolTip { text: i18n("Call") }
                    onLinkActivated: Qt.openUrlExternally(link)
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(`tel:${model.display}`)
                    }
                }
            }
        }
    }
}
