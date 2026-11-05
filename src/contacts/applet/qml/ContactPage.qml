// SPDX-FileCopyrightText: 2022 Carl Schwan <car@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.merkuro.contact
import org.kde.ki18n
import "." as Applet

PlasmaComponents3.ScrollView {
    id: root

    property int itemId
    topPadding: 0

    property string title: root.addressee.formattedName
    readonly property QQC2.StackView pageStack: root.QQC2.StackView.view
    readonly property bool hasBirthday: !isNaN(root.addressee.birthday.getTime())

    property AddresseeWrapper addressee: AddresseeWrapper {
        addresseeItem: ContactManager.getItem(root.itemId)
    }
    PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

    function callNumber(number: string): void {
        Qt.openUrlExternally("tel:" + number)
    }

    function sendSms(number: string): void {
        Qt.openUrlExternally("sms:" + number)
    }

    Keys.onPressed: function(event: KeyEvent): void {
        if (event.key === Qt.Key_Escape) {
            root.pageStack.pop();
            event.accepted = true;
        }
    }

    property var header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            width: parent.width

            PlasmaComponents3.Button {
                icon.name: "go-previous-view"
                text: KI18n.i18n("Return to Contact List")
                onClicked: root.pageStack.pop()
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                id: configureButtonCall
                objectName: "callButton"
                Accessible.name: KI18n.i18n("Call")
                PlasmaComponents3.ToolTip { text: KI18n.i18n("Call") }
                icon.name: "call-start"
                visible: addressee.phoneNumbers.length > 0
                onClicked: {
                    if (root.addressee.phoneNumbers.length === 1) {
                        root.callNumber(root.addressee.phoneNumbers[0].normalizedNumber);
                    } else {
                        menuCall.open();
                    }
                }
                PlasmaComponents3.Menu {
                    id: menuCall
                    objectName: "callMenu"
                    y: configureButtonCall.height

                    Instantiator {
                        model: root.addressee.phoneNumbers
                        delegate: PlasmaComponents3.MenuItem {
                            required property var modelData

                            text: KI18n.i18n("%1 (%2)", modelData.typeLabel, modelData.number)
                            onTriggered: root.callNumber(modelData.normalizedNumber)
                        }
                        onObjectAdded: function(index: int, object: QtObject): void { menuCall.insertItem(index, object); }
                        onObjectRemoved: function(index: int, object: QtObject): void { menuCall.removeItem(object); }
                    }
                }
            }

            PlasmaComponents3.ToolButton {
                id: configureButtonSms
                objectName: "smsButton"
                Accessible.name: KI18n.i18n("Send SMS")
                PlasmaComponents3.ToolTip { text: KI18n.i18n("Send SMS") }
                icon.name: "mail-message"
                visible: addressee.phoneNumbers.length > 0
                onClicked: {
                    if (root.addressee.phoneNumbers.length === 1) {
                        root.sendSms(root.addressee.phoneNumbers[0].normalizedNumber);
                    } else {
                        menuSms.open();
                    }
                }
                PlasmaComponents3.Menu {
                    id: menuSms
                    objectName: "smsMenu"
                    y: configureButtonSms.height

                    Instantiator {
                        model: root.addressee.phoneNumbers
                        delegate: PlasmaComponents3.MenuItem {
                            required property var modelData

                            text: KI18n.i18n("%1 (%2)", modelData.typeLabel, modelData.number)
                            onTriggered: root.sendSms(modelData.normalizedNumber)
                        }
                        onObjectAdded: function(index: int, object: QtObject): void { menuSms.insertItem(index, object); }
                        onObjectRemoved: function(index: int, object: QtObject): void { menuSms.removeItem(object); }
                    }
                }
            }

            PlasmaComponents3.ToolButton {
                Accessible.name: KI18n.i18n("Send Email")
                PlasmaComponents3.ToolTip { text: KI18n.i18n("Send Email") }
                icon.name: "mail-message"
                visible: addressee.preferredEmail.length > 0
                onClicked: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
            }

            PlasmaComponents3.ToolButton {
                icon.name: 'view-barcode-qr'
                Accessible.name: KI18n.i18n("Show QR Code")
                PlasmaComponents3.ToolTip { text: KI18n.i18n("Show QR Code") }
                onClicked: root.pageStack.push(Qt.resolvedUrl('./QrCodePage.qml'), {
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
            Applet.Header {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8

                name: root.addressee.formattedName
                photoUrl: addressee.photoUrl
                backgroundSource: "qrc:/qt/qml/plasma/applet/org/kde/merkuro/contact/applet/fallbackBackground.png"

                contentItems: PlasmaExtras.Heading {
                    text: addressee.formattedName
                    color: "#fcfcfc"
                    level: 2
                }
            }

            PlasmaComponents3.Label {
                visible: addressee.nickName !== ""
                text: KI18n.i18n("Nickname: %1", addressee.nickName)
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            PlasmaComponents3.Label {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                objectName: "birthdayLabel"
                visible: root.hasBirthday
                text: if (!root.hasBirthday) {
                    return "";
                } else if (addressee.birthday.getFullYear() === 0) {
                    return Qt.formatDate(addressee.birthday, KI18n.i18nc("Day month format", "dd.MM."))
                } else {
                    return KI18n.i18n("Birthday:") + ' ' + addressee.birthday.toLocaleDateString()
                }
            }

            PlasmaExtras.Heading {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                visible: addressesRepeater.count > 0
                text: KI18n.i18np("Address", "Addresses", addressesRepeater.count)
                level: 4
            }

            Repeater {
                id: addressesRepeater
                model: root.addressee.addressesModel
                PlasmaComponents3.Label {
                    id: addressDelegate
                    objectName: "addressDelegate"

                    required property string typeLabel
                    required property string formattedAddress

                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    visible: addressDelegate.formattedAddress.length > 0
                    text: (addressDelegate.typeLabel ? KI18n.i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", addressDelegate.typeLabel) : '') + ' ' + addressDelegate.formattedAddress
                }
            }

            PlasmaExtras.Heading {
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: emailRepeater.count > 0
                text: KI18n.i18np("Email Address", "Email Addresses", emailRepeater.count)
                level: 4
            }

            Repeater {
                id: emailRepeater
                model: root.addressee.emailModel
                PlasmaComponents3.Label {
                    id: emailDelegate
                    objectName: "emailDelegate"

                    required property string type
                    required property string email

                    visible: emailDelegate.email.length > 0
                    text: `${emailDelegate.type} <a href="mailto:${emailDelegate.email}">${emailDelegate.email}</a>`
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    PlasmaComponents3.ToolTip { text: KI18n.i18n("Send Email") }
                    onLinkActivated: function(link: string): void { Qt.openUrlExternally(link); }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(`mailto:${emailDelegate.email}`)
                    }
                }
            }

            PlasmaExtras.Heading {
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                visible: phoneRepeater.count > 0
                text: KI18n.i18np("Phone number", "Phone numbers", phoneRepeater.count)
                level: 4
            }

            Repeater {
                id: phoneRepeater
                model: root.addressee.phoneModel

                RowLayout {
                    id: phoneRow

                    required property int index
                    required property string phoneNumber
                    required property string type

                    visible: phoneRow.phoneNumber.length > 0
                    PlasmaComponents3.Label {
                        id: phoneNumberLabel
                        text: KI18n.i18n("%1:", phoneRow.type) + ` <a href="tel:${phoneRow.phoneNumber}">${phoneRow.phoneNumber}</a>`
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                        PlasmaComponents3.ToolTip { text: KI18n.i18n("Call") }
                        onLinkActivated: function(link: string): void { Qt.openUrlExternally(link); }
                        MouseArea {
                            id: phoneNumberMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(`tel:${phoneRow.phoneNumber}`)
                        }
                    }
                    PlasmaComponents3.ToolButton {
                        id: phoneNumberCopyButton
                        icon.name: 'edit-copy'
                        Accessible.name: KI18n.i18n("Copy phone number")
                        PlasmaComponents3.ToolTip { text: KI18n.i18n("Copy phone number to clipboard") }
                        onClicked: {
                            root.addressee.phoneModel.copyToClipboard(phoneRow.index);
                        }
                    }
                }
            }
        }
    }
}
