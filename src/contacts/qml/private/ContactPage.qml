// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.merkuro.contact

FormCard.FormCardPage {
    id: page

    property int itemId
    property AddresseeWrapper addressee: AddresseeWrapper {
        id: addressee
        addresseeItem: ContactManager.getItem(page.itemId)
    }

    title: addressee.formattedName

    function openEditor() {
        pageStack.pushDialogLayer(Qt.resolvedUrl("./contact_editor/ContactEditorPage.qml"), {
            mode: ContactEditor.EditMode,
            item: page.addressee.addresseeItem,
        })
    }

    actions: [
        Kirigami.Action {
            icon.name: "document-edit"
            text: i18nc("@action:inmenu", "Edit")
            onTriggered: openEditor()
        },
        DeleteContactAction {
            name: page.addressee.formattedName
            item: page.addressee.addresseeItem
        },
        Kirigami.Action {
            text: i18nc("@action:inmenu", "Cancel")
            icon.name: "dialog-cancel"
            visible: Kirigami.Settings.isMobile

            onTriggered: pageStack.pop()
        }
    ]

    function callNumber(number) {
        Qt.openUrlExternally("tel:" + number)
    }

    function sendSms(number) {
        Qt.openUrlExternally("sms:" + number)
    }

    Header {
        Layout.fillWidth: true
        source: addressee.photo.isIntern ? addressee.photo.data : addressee.photo.url
        name: addressee.formattedName.trim().length > 0 ? addressee.formattedName : i18nc("Placeholder", "No Name")
        actions: [
            Kirigami.Action {
                text: i18n("Call")
                icon.name: "call-start"
                visible: addressee.phoneNumbers.length > 0
                onTriggered: {
                    const model = addressee.phoneNumbers;

                    if (addressee.phoneNumbers.length === 1) {
                        page.callNumber(model[0].normalizedNumber);
                    } else {
                        const pop = callPopup.createObject(page, {
                            numbers: addressee.phoneNumbers,
                            title: i18n("Select number to call")
                        });
                        pop.onNumberSelected.connect(number => callNumber(number));
                        pop.open();
                    }
                }
            },
            Kirigami.Action {
                text: i18n("Send SMS")
                icon.name: "mail-message"
                visible: addressee.phoneNumbers.length > 0
                onTriggered: {
                    const model = addressee.phoneNumbers;

                    if (addressee.phoneNumbers.length === 1) {
                        page.sendSms(model[0].normalizedNumber);
                    } else {
                        const pop = callPopup.createObject(page, {
                            numbers: addressee.phoneNumbers,
                            title: i18n("Select number to send message to"),
                        });
                        pop.onNumberSelected.connect(number => sendSms(number));
                        pop.open();
                    }
                }
            },
            Kirigami.Action {
                text: i18n("Send email")
                icon.name: "mail-message"
                visible: addressee.preferredEmail.length > 0
                onTriggered: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
            },
            Kirigami.Action {
                text: i18n("Show QR Code")
                icon.name: 'view-barcode-qr'
                onTriggered: pageStack.layers.push(Qt.resolvedUrl('./QrCodePage.qml'), {
                    qrCodeData: addressee.qrCodeData(),
                })
            }
        ]

        Component {
            id: callPopup

            PhoneNumberDialog {}
        }
    }

    FormCard.FormHeader {
        title: i18n("Contact information")
    }

    FormCard.FormCard {
        FormCard.FormTextDelegate {
            visible: description !== ""
            description: addressee.formattedName
            text: i18n("Name:")
        }

        FormCard.FormTextDelegate {
            visible: description !== ""
            description: addressee.nickName
            text: i18n("Nickname:")
        }

        FormCard.FormButtonDelegate {
            id: blogFeed
            visible: addressee.blogFeed + '' !== ''
            text: i18n("Blog Feed:")
            // We do not always have the year
            description: `<a href="${addressee.blogFeed}">${addressee.blogFeed}</a>`
            onClicked: Qt.openUrlExternally(addressee.blogFeed)
        }
    }

    FormCard.FormHeader {
        title: i18n("Personal information")
        visible: birthday.visible || anniversary.visible || spousesName.visible
    }

    FormCard.FormCard {
        visible: birthday.visible || anniversary.visible || spousesName.visible

        FormCard.FormTextDelegate {
            id: birthday
            visible: description !== ""
            text: i18n("Birthday:")
            // We do not always have the year
            description: if (addressee.birthday.getFullYear() === 0) {
                return Qt.formatDate(addressee.birthday, i18nc('Day month format', 'dd.MM.'))
            } else {
                return addressee.birthday.toLocaleDateString()
            }
        }

        FormCard.FormTextDelegate {
            id: anniversary
            visible: description !== ""
            // We do not always have the year
            description: if (addressee.anniversary.getFullYear() === 0) {
                return Qt.formatDate(addressee.anniversary, i18nc('Day month format', 'dd.MM.'))
            } else {
                return addressee.anniversary.toLocaleDateString()
            }
            text: i18n("Anniversary:")
        }

        FormCard.FormTextDelegate {
            id: spousesName
            visible: description !== ""
            description: addressee.spousesName
            text: i18n("Partner's name:")
        }
    }

    FormCard.FormHeader {
        title: i18np("Phone Number", "Phone Numbers", addressee.phoneModel.count)
        visible: phoneRepeater.count > 0
    }

    FormCard.FormCard {
        visible: phoneRepeater.count > 0

        Repeater {
            id: phoneRepeater

            model: addressee.phoneModel
            delegate: FormCard.FormButtonDelegate {
                required property string phoneNumber
                required property string type

                visible: text.length > 0
                text: i18nc("Label for a phone number type", "%1:", type)
                description: phoneNumber
                onClicked: Qt.openUrlExternally(link)
            }
        }
    }

    FormCard.FormHeader {
        title: i18np("Address", "Addresses", addressesRepeater.count)
        visible: addressesRepeater.count > 0
    }

    FormCard.FormCard {
        visible: addressesRepeater.count > 0

        Repeater {
            id: addressesRepeater
            model: addressee.addressesModel

            delegate: FormCard.FormTextDelegate {
                required property string formattedAddress
                required property string typeLabel

                visible: text.length > 0

                text: typeLabel ? i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", typeLabel) : i18n("Home:")
                description: formattedAddress
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Instant Messaging")
        visible: imppRepeater.count > 0
    }

    FormCard.FormCard {
        visible: imppRepeater.count > 0

        Repeater {
            id: imppRepeater

            model: addressee.imppModel
            delegate: FormCard.FormButtonDelegate {
                id: imppDelegate

                required property string url
                readonly property var parts: url.split(':')
                readonly property string protocol: parts.length > 0 ? parts[0] : ''
                readonly property string address: parts.length > 0 ? parts.slice(1, parts.length).join(':') : ''
                readonly property bool isMatrix: protocol === 'matrix'

                visible: text !== ""
                text: i18nc("Label for a messaging protocol", "%1:", isMatrix ? 'Matrix' : protocol)
                description: address

                onClicked: Qt.openUrlExternally(parent.url)
            }
        }
    }

    FormCard.FormHeader {
        title: i18n("Business Information")
        visible: businessCard.visible
    }

    FormCard.FormCard {
        id: businessCard

        visible: addressee.organization.length > 0
            || addressee.profession.length > 0
            || addressee.title.length > 0
            || addressee.department.length > 0
            || addressee.office.length > 0
            || addressee.managersName.length > 0
            || addressee.assistantsName.length > 0


        FormCard.FormTextDelegate {
            id: organization
            visible: description.length > 0
            text: i18n("Organization:")
            description: addressee.organization
        }

        FormCard.FormTextDelegate {
            id: profession
            visible: description.length > 0
            text: i18n("Profession:")
            description: addressee.profession
        }

        FormCard.FormTextDelegate {
            id: title
            visible: description !== ''
            text: i18n("Title:")
            description: addressee.title
        }

        FormCard.FormTextDelegate {
            id: department
            visible: description !== ''
            text: i18n("Department:")
            description: addressee.department
        }

        FormCard.FormTextDelegate {
            id: office
            visible: description.length > 0
            text: i18n("Office:")
            description: addressee.office
        }

        FormCard.FormTextDelegate {
            id: managersName
            visible: description.length > 0
            text: i18n("Manager's name:")
            description: addressee.managersName
        }

        FormCard.FormTextDelegate {
            id: assistantsName
            visible: description.length > 0
            text: i18n("Assistants's name:")
            description: addressee.assistantsName
        }
    }

    FormCard.FormHeader {
        title: i18np("Email Address", "Email Addresses", emailRepeater.count > 0)
        visible: emailRepeater.count > 0
    }

    FormCard.FormCard {
        visible: emailRepeater.count > 0

        Repeater {
            id: emailRepeater

            model: addressee.emailModel
            delegate: FormCard.FormButtonDelegate {
                required property string email

                text: email
                onClicked: Qt.openUrlExternally(`mailto:${email}`)
            }
        }
    }
}
