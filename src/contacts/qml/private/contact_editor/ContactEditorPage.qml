// SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import org.kde.ki18n

FormCard.FormCardPage {
    id: root

    property alias mode: contactEditor.mode
    property alias item: contactEditor.item
    property double initialCollectionId: -1

    property bool displayAdvancedNameFields: false
    readonly property bool saving: contactEditor.saving

    readonly property ContactEditor contactEditor: ContactEditor {
        id: contactEditor
        mode: ContactEditor.CreateMode
        onFinished: {
            ContactConfig.lastUsedAddressBookCollection = addressBookEditorCard.addressBookComboBox.currentValue;
            ContactConfig.save();
            root.Kirigami.PageStack.closeDialog();
        }
        onErrorOccured: errorMsg => {
            errorContainer.displayError = true;
            errorContainer.errorMessage = errorMsg;
        }
        onItemChangedExternally: itemChangedExternallySheet.open()
    }

    function isNotEmptyStr(str) {
        return str.trim().length > 0;
    }
    data: QQC2.Action {
        id: submitAction
        objectName: "submitAction"
        enabled: contactEditor.contact.formattedName.length > 0
        shortcut: "Return"
        onTriggered: {
            if (phoneEditorId.phoneText.length > 0) {
                contactEditor.contact.phoneModel.addPhoneNumber(phoneEditorId.phoneText, phoneEditorId.newPhoneTypeComboText)
            }
            if (emailEditorId.toAddEmailText.length > 0) {
                contactEditor.contact.emailModel.addEmail(emailEditorId.toAddEmailText, emailEditorId.newEmailTypeCurrentValue);
            }
            if (root.mode === ContactEditor.CreateMode && addressBookEditorCard.addressBookComboBox.currentIndex >= 0) {
                contactEditor.collectionId = addressBookEditorCard.addressBookComboBox.currentValue
            }
            contactEditor.saveContactInAddressBook()
        }
    }

    title: if (mode === ContactEditor.CreateMode) {
        return KI18n.i18n("Add Contact");
    } else {
        return KI18n.i18n("Edit Contact");
    }

    enabled: !contactEditor.isReadOnly && !contactEditor.saving

    //property FileDialog fileDialog: FileDialog {
    //    id: fileDialog

    //    onAccepted: {
    //        root.pendingPhoto = ContactController.preparePhoto(currentFile)
    //    }
    //}

    header: QQC2.Control {
        id: errorContainer
        property bool displayError: false
        property string errorMessage: ''
        padding: contentItem.visible ? Kirigami.Units.smallSpacing : 0
        leftPadding: padding
        rightPadding: padding
        topPadding: padding
        bottomPadding: padding
        contentItem: Kirigami.InlineMessage {
            type: Kirigami.MessageType.Error
            visible: errorContainer.displayError
            text: errorContainer.errorMessage
            showCloseButton: true
        }
    }

    PhotoEditor {
        contactEditor: root.contactEditor
    }

    AddressBookEditorCard {
        id: addressBookEditorCard
        contactEditor: root.contactEditor
        mode: root.mode
        initialCollectionId: root.initialCollectionId
        displayAdvancedNameFields: root.displayAdvancedNameFields
        onToggleAdvancedNameFields: root.displayAdvancedNameFields = !root.displayAdvancedNameFields
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Personal Information")
    }

    PersonalInfoEditorCard {
        contactEditor: root.contactEditor
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Business Information")
    }

    BusinessEditorCard {
        contactEditor: root.contactEditor
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Phone")
    }

    PhoneEditorCard {
        id: phoneEditorId
        contactEditor: root.contactEditor
    }

    FormCard.FormHeader {
        title: KI18n.i18n("E-mail")
    }

    EmailEditorCard {
        id: emailEditorId
        contactEditor: root.contactEditor
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group", "Addresses")
    }

    AddressEditorCard {
        contactEditor: root.contactEditor
        onAddressRequested: row => (root.Kirigami.PageStack.pageStack as Kirigami.PageRow).pushDialogLayer(Qt.resolvedUrl("./AddressEditorPage.qml"), {
            addressModel: root.contactEditor.contact.addressesModel,
            row: row,
        })
    }

    FormCard.FormHeader {
        title: KI18n.i18n("Instant Messenger")
    }

    InstantMessengerEditorCard {
        contactEditor: root.contactEditor
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group", "Notes")
    }

    FormCard.FormCard {
        QQC2.ScrollView {
            id: noteScrollView
            objectName: "contactNoteScrollView"
            background: null
            contentWidth: availableWidth
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6

            QQC2.TextArea {
                objectName: "contactNoteField"
                Accessible.name: KI18n.i18nc("@label:textbox", "Notes")
                placeholderText: KI18n.i18nc("@info:placeholder", "Add a note")
                text: root.contactEditor.contact.note
                onTextChanged: root.contactEditor.contact.note = text
                wrapMode: TextEdit.Wrap
                background: null
                width: noteScrollView.availableWidth

                leftPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                rightPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                topPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                bottomPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
            }
        }
    }


    footer: ColumnLayout {
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.DialogButtonBox {
            Layout.fillWidth: true

            standardButtons: QQC2.DialogButtonBox.Cancel

            QQC2.Button {
                icon.name: root.mode === ContactEditor.EditMode ? "document-save" : "list-add"
                text: root.mode === ContactEditor.EditMode ? KI18n.i18n("Save") : KI18n.i18n("Add")
                enabled: contactEditor.contact.formattedName.length > 0 && !contactEditor.saving
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: {
                if (addressBookEditorCard.addressBookComboBox.currentIndex >= 0) {
                    ContactConfig.lastUsedAddressBookCollection = addressBookEditorCard.addressBookComboBox.currentValue;
                    ContactConfig.save();
                }
                root.Kirigami.PageStack.closeDialog();
            }
            onAccepted: submitAction.trigger();
        }
    }

    property QQC2.Dialog itemChangedExternallySheet: QQC2.Dialog {
        id: itemChangedExternallySheet
        visible: false
        title: KI18n.i18n("Warning")
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: parent.height / 3
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 30)

        contentItem: ColumnLayout {
            Kirigami.Heading {
                level: 4
                text: KI18n.i18n("This contact was changed elsewhere during editing.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: KI18n.i18n("Which changes should be kept?")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        onRejected: {
            contactEditor.fetchItem();
            itemChangedExternallySheet.close();
        }
        onAccepted: itemChangedExternallySheet.close()

        footer: QQC2.DialogButtonBox {
            QQC2.Button {
                text: KI18n.i18n("Current changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                text: KI18n.i18n("External changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
            }
        }
    }


}
