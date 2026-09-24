// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCardPage {
    id: page

    property int itemId
    property AddresseeWrapper addressee: AddresseeWrapper {
        id: addressee
        addresseeItem: ContactManager.getItem(page.itemId)
    }

    title: addressee.formattedName

    function openEditor(): void {
        pageStack.pushDialogLayer(Qt.resolvedUrl("./contact_editor/ContactEditorPage.qml"), {
            mode: ContactEditor.EditMode,
            item: page.addressee.addresseeItem,
        })
    }

    actions: [
        Kirigami.Action {
            icon.name: "document-edit"
            text: KI18n.i18nc("@action:inmenu", "Edit")
            onTriggered: openEditor()
        },
        Kirigami.Action {
            fromQAction: ContactApplication.action('contact_delete')
        },
        Kirigami.Action {
            icon.name: "document-export"
            text: KI18n.i18nc("@action:inmenu", "Export Contact…")
	    displayHint: Kirigami.DisplayHint.AlwaysHide
            onTriggered: exportFileDialog.open()
        },
        ShareAction {
            application: page.QQC2.ApplicationWindow.window
            exporter: contactExporter
            itemId: page.itemId
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action:inmenu", "Cancel")
            icon.name: "dialog-cancel"
            visible: Kirigami.Settings.isMobile

            onTriggered: pageStack.pop()
        }
    ]

    ContactImportExport {
        id: contactExporter

        onExportFinished: (success, count, errorMessage) => {
            if (success) {
                page.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18n("Contact exported successfully."), "short");
            } else {
                page.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18n("Could not export contact: %1", errorMessage), "long");
            }
        }
    }

    FileDialog {
        id: exportFileDialog
        title: KI18n.i18n("Export contact")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "vcf"
        nameFilters: [KI18n.i18n("vCard files (*.vcf)")]

        onAccepted: contactExporter.exportContact(exportFileDialog.selectedFile, page.itemId)
    }

    function callNumber(number): void {
        Qt.openUrlExternally("tel:" + number)
    }

    function sendSms(number): void {
        Qt.openUrlExternally("sms:" + number)
    }

    Header {
        Layout.fillWidth: true
        photoUrl: addressee.photoUrl
        name: addressee.formattedName.trim().length > 0 ? addressee.formattedName : (addressee.preferredEmail.trim().length > 0 ? addressee.preferredEmail : KI18n.i18nc("@info:placeholder", "No name"))
        actions: [
            Kirigami.Action {
                text: KI18n.i18n("Call")
                icon.name: "call-start"
                visible: addressee.phoneNumbers.length > 0
                onTriggered: {
                    const model = addressee.phoneNumbers;

                    if (addressee.phoneNumbers.length === 1) {
                        page.callNumber(model[0].normalizedNumber);
                    } else {
                        const pop = callPopup.createObject(page, {
                            numbers: addressee.phoneNumbers,
                            title: KI18n.i18n("Select number to call")
                        });
                        pop.onNumberSelected.connect(number => callNumber(number));
                        pop.open();
                    }
                }
            },
            Kirigami.Action {
                text: KI18n.i18n("Send SMS")
                icon.name: "mail-message"
                visible: addressee.phoneNumbers.length > 0
                onTriggered: {
                    const model = addressee.phoneNumbers;

                    if (addressee.phoneNumbers.length === 1) {
                        page.sendSms(model[0].normalizedNumber);
                    } else {
                        const pop = callPopup.createObject(page, {
                            numbers: addressee.phoneNumbers,
                            title: KI18n.i18n("Select number to send message to"),
                        });
                        pop.onNumberSelected.connect(number => sendSms(number));
                        pop.open();
                    }
                }
            },
            Kirigami.Action {
                text: KI18n.i18n("Send email")
                icon.name: "mail-message"
                visible: addressee.preferredEmail.length > 0
                onTriggered: Qt.openUrlExternally(`mailto:${addressee.preferredEmail}`)
            },
            Kirigami.Action {
                text: KI18n.i18n("Show QR Code")
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
        title: KI18n.i18n("Contact information")
        visible: contactInfoCard.visible
    }

    FormCard.FormCard {
        id: contactInfoCard

        visible: addressee.formattedName.trim().length > 0
            || addressee.nickName.trim().length > 0
            || addressee.blogFeed.length > 0

        FormCard.FormTextDelegate {
            id: nameField
            visible: description.length > 0
            description: addressee.formattedName.trim()
            text: KI18n.i18n("Name:")
        }

        FormCard.FormTextDelegate {
            id: nickNameField
            visible: description.length > 0
            description: addressee.nickName.trim()
            text: KI18n.i18n("Nickname:")
        }

        FormCard.FormLinkDelegate {
            id: blogFeedField
            visible: description.length > 0
            text: KI18n.i18n("Blog Feed:")
            description: addressee.blogFeed
            url: addressee.blogFeed
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Personal information")
        visible: personalInfoCard.visible
    }

    FormCard.FormCard {
        id: personalInfoCard

        visible: birthday.visible || anniversary.visible || spousesName.visible

        FormCard.FormTextDelegate {
            id: birthday
            visible: description !== ""
            text: KI18n.i18n("Birthday:")
            // We do not always have the year
            description: if (addressee.birthday.getFullYear() === 0) {
                return Qt.formatDate(addressee.birthday, KI18n.i18nc('Day month format', 'dd.MM.'))
            } else {
                return addressee.birthday.toLocaleDateString()
            }
        }

        FormCard.FormTextDelegate {
            id: anniversary
            visible: description !== ""
            // We do not always have the year
            description: if (addressee.anniversary.getFullYear() === 0) {
                return Qt.formatDate(addressee.anniversary, KI18n.i18nc('Day month format', 'dd.MM.'))
            } else {
                return addressee.anniversary.toLocaleDateString()
            }
            text: KI18n.i18n("Anniversary:")
        }

        FormCard.FormTextDelegate {
            id: spousesName
            visible: description !== ""
            description: addressee.spousesName
            text: KI18n.i18n("Partner's name:")
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18np("Phone Number", "Phone Numbers", addressee.phoneModel.count)
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
                required property int index

                visible: text.length > 0
                trailingLogo {
                    source: "edit-copy-symbolic"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                text: KI18n.i18nc("Label for a phone number type", "%1:", type)
                description: phoneNumber
                onClicked: {
                    addressee.phoneModel.copyToClipboard(index);
                    applicationWindow().showPassiveNotification(KI18n.i18n("Phone number copied to clipboard"));
                }
            }
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18np("Address", "Addresses", addressesRepeater.count)
        visible: addressesRepeater.count > 0
    }

    FormCard.FormCard {
        visible: addressesRepeater.count > 0

        Repeater {
            id: addressesRepeater
            model: addressee.addressesModel

            delegate: FormCard.FormButtonDelegate {
                required property string formattedAddress
                required property string typeLabel
                required property url geoUri

                visible: geoUri.toString().length > 0

                text: typeLabel ? KI18n.i18nc("%1 is the type of the address, e.g. home, work, ...", "%1:", typeLabel) : KI18n.i18n("Home:")
                description: formattedAddress
                trailingLogo {
                    source: "map-symbolic"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                Accessible.name: formattedAddress.trim().length > 0
                    ? KI18n.i18nc("@action:button Accessible name for opening a contact address in a map", "Show %1 on a map", formattedAddress)
                    : KI18n.i18nc("@action:button Accessible name for opening contact coordinates in a map", "Show location on a map")
                onClicked: Qt.openUrlExternally(geoUri)
            }
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Instant Messaging")
        visible: imppRepeater.count > 0
    }

    FormCard.FormCard {
        visible: imppRepeater.count > 0

        Repeater {
            id: imppRepeater

            model: addressee.imppModel
            delegate: FormCard.FormButtonDelegate {
                id: imppDelegate

                required property string username
                required property string typeLabel
                required property string typeIcon

                visible: text !== ""
                text: KI18n.i18nc("Label for a messaging protocol", "%1:", typeLabel)
                description: username

                trailingLogo.source: "edit-copy-symbolic"
                trailingLogo.implicitWidth: Kirigami.Units.iconSizes.small
                trailingLogo.implicitHeight: Kirigami.Units.iconSizes.small

                icon.name: typeIcon

                onClicked: {
                    addressee.imppModel.copyToClipboard(imppRepeater.index);
                    applicationWindow().showPassiveNotification(KI18n.i18n("Instant Messaging ID copied to clipboard"));
                }
            }
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Business Information")
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
            text: KI18n.i18n("Organization:")
            description: addressee.organization
        }

        FormCard.FormTextDelegate {
            id: profession
            visible: description.length > 0
            text: KI18n.i18n("Profession:")
            description: addressee.profession
        }

        FormCard.FormTextDelegate {
            id: title
            visible: description !== ''
            text: KI18n.i18n("Title:")
            description: addressee.title
        }

        FormCard.FormTextDelegate {
            id: department
            visible: description !== ''
            text: KI18n.i18n("Department:")
            description: addressee.department
        }

        FormCard.FormTextDelegate {
            id: office
            visible: description.length > 0
            text: KI18n.i18n("Office:")
            description: addressee.office
        }

        FormCard.FormTextDelegate {
            id: managersName
            visible: description.length > 0
            text: KI18n.i18n("Manager's name:")
            description: addressee.managersName
        }

        FormCard.FormTextDelegate {
            id: assistantsName
            visible: description.length > 0
            text: KI18n.i18n("Assistant's name:")
            description: addressee.assistantsName
        }
    }

    FormCard.FormHeader {
        title: KI18n.i18np("Email Address", "Email Addresses", emailRepeater.count > 0)
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

    FormCard.FormHeader {
        visible: certificateRepeater.count > 0
        title: KI18n.i18nc("@title:group", "Cryptographic Certificates")
    }

    FormCard.FormCard {
        visible: certificateRepeater.count > 0
        Repeater {
            id: certificateRepeater

            model: CertificatesModel {
                id: certificatesModel

                emails: addressee.emailModel.emails
            }
            delegate: FormCard.AbstractFormDelegate {
                id: certificateDelegate

                required property int index
                required property string displayName
                required property string fingerprint
                required property string fingerprintAccess
                required property var tags

                text: displayName
                Accessible.description: fingerprintAccess

                onClicked: certificatesModel.openKleopatra(index, QQC2.ApplicationWindow.window)

                contentItem: RowLayout {
                    spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: certificateDelegate.text
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            Accessible.ignored: true // base class sets this text on root already
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: certificateDelegate.fingerprint
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            Accessible.ignored: true // base class sets this text on root already
                        }

                        Flow {
                            Layout.fillWidth: true

                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: certificateDelegate.tags

                                Kirigami.Chip {
                                    text: modelData
                                    closable: false
                                }
                            }
                        }
                    }

                    FormCard.FormArrow {
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        direction: Qt.RightArrow
                    }
                }
            }
        }
    }
}
