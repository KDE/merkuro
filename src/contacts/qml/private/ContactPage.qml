// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.merkuro.contact
import org.kde.ki18n

FormCard.FormCardPage {
    id: page

    property int itemId
    readonly property Kirigami.ApplicationWindow appWindow: page.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow
    readonly property Kirigami.PageRow pageStack: page.appWindow.pageStack as Kirigami.PageRow
    property AddresseeWrapper addressee: AddresseeWrapper {
        id: addressee
        addresseeItem: ContactManager.getItem(page.itemId)
    }
    readonly property bool hasBirthday: !isNaN(addressee.birthday.getTime())
    readonly property bool hasAnniversary: !isNaN(addressee.anniversary.getTime())
    readonly property string birthdayText: {
        if (!page.hasBirthday) {
            return "";
        }
        // A year of zero means that only the day and month are known.
        if (addressee.birthday.getFullYear() === 0) {
            return Qt.formatDate(addressee.birthday, KI18n.i18nc("Day month format", "dd.MM."));
        }
        return addressee.birthday.toLocaleDateString();
    }

    title: addressee.formattedName

    function openEditor(): void {
        page.pageStack.pushDialogLayer(Qt.resolvedUrl("./contact_editor/ContactEditorPage.qml"), {
            mode: ContactEditor.EditMode,
            item: page.addressee.addresseeItem,
        })
    }

    actions: [
        Kirigami.Action {
            icon.name: "document-edit"
            text: KI18n.i18nc("@action:inmenu", "Edit")
            onTriggered: page.openEditor()
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
            application: page.appWindow
            exporter: contactExporter
            itemId: page.itemId
        },
        Kirigami.Action {
            text: KI18n.i18nc("@action:inmenu", "Cancel")
            icon.name: "dialog-cancel"
            visible: Kirigami.Settings.isMobile

            onTriggered: page.pageStack.pop()
        }
    ]

    ContactImportExport {
        id: contactExporter

        onExportFinished: (success, count, errorMessage) => {
            if (success) {
                page.appWindow.showPassiveNotification(KI18n.i18n("Contact exported successfully."), "short");
            } else {
                page.appWindow.showPassiveNotification(KI18n.i18n("Could not export contact: %1", errorMessage), "long");
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
        subtitle: page.hasBirthday ? KI18n.i18nc("@info:label Contact birthday", "Birthday: %1", page.birthdayText) : ""
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
                        }) as PhoneNumberDialog;
                        pop.numberSelected.connect(number => page.callNumber(number));
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
                        }) as PhoneNumberDialog;
                        pop.numberSelected.connect(number => page.sendSms(number));
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
                onTriggered: page.pageStack.layers.push(Qt.resolvedUrl('./QrCodePage.qml'), {
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
            || addressee.blogFeed.toString().length > 0

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

        visible: anniversary.visible || spousesName.visible

        FormCard.FormTextDelegate {
            id: anniversary
            visible: page.hasAnniversary
            // We do not always have the year
            description: {
                if (!page.hasAnniversary) {
                    return "";
                }
                if (addressee.anniversary.getFullYear() === 0) {
                    return Qt.formatDate(addressee.anniversary, KI18n.i18nc("Day month format", "dd.MM."));
                }
                return addressee.anniversary.toLocaleDateString();
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
        title: KI18n.i18np("Phone Number", "Phone Numbers", addressee.phoneModel.rowCount())
        visible: phoneRepeater.count > 0
    }

    FormCard.FormCard {
        visible: phoneRepeater.count > 0
        Component.onCompleted: autoSeparators = true

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
                    page.appWindow.showPassiveNotification(KI18n.i18n("Phone number copied to clipboard"));
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
        Component.onCompleted: autoSeparators = true

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
        Component.onCompleted: autoSeparators = true

        Repeater {
            id: imppRepeater

            model: addressee.imppModel
            delegate: FormCard.FormButtonDelegate {
                id: imppDelegate

                required property int index
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
                    addressee.imppModel.copyToClipboard(imppDelegate.index);
                    page.appWindow.showPassiveNotification(KI18n.i18n("Instant Messaging ID copied to clipboard"));
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
        Component.onCompleted: autoSeparators = true

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
        title: KI18n.i18nc("@title:group", "Notes")
        visible: addressee.note.trim().length > 0
    }

    FormCard.FormCard {
        visible: addressee.note.trim().length > 0

        FormCard.FormTextDelegate {
            objectName: "contactNoteDisplay"
            description: addressee.note
            descriptionItem.textFormat: Text.PlainText
        }
    }

    ContactActivityModel {
        id: recentMessages
        kind: ContactActivityModel.Messages
        emails: addressee.emailModel.emails
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group", "Recent emails")
        visible: recentMessages.count > 0
    }

    FormCard.FormCard {
        visible: recentMessages.count > 0
        Component.onCompleted: autoSeparators = true

        Repeater {
            model: recentMessages
            delegate: ContactActivityDelegate {
                required property int index
                kind: ContactActivityModel.Messages
                onActivated: recentMessages.openMessage(index)
            }
        }
    }

    ContactActivityModel {
        id: recentEvents
        kind: ContactActivityModel.Events
        emails: addressee.emailModel.emails
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group", "Recent events")
        visible: recentEvents.count > 0
    }

    FormCard.FormCard {
        visible: recentEvents.count > 0
        Component.onCompleted: autoSeparators = true

        Repeater {
            model: recentEvents
            delegate: ContactActivityDelegate {
                kind: ContactActivityModel.Events
            }
        }
    }

    FormCard.FormHeader {
        visible: certificateRepeater.count > 0
        title: KI18n.i18nc("@title:group", "Cryptographic Certificates")
    }

    FormCard.FormCard {
        visible: certificateRepeater.count > 0
        Component.onCompleted: autoSeparators = true

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
                                    required property string modelData
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
