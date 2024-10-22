// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami 2 as Kirigami
import org.kde.kirigamiaddons.formcard 1 as FormCard
import org.kde.kirigamiaddons.components 1 as Components
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi

FormCard.FormCardPage {
    id: root

    property alias mode: contactGroupEditor.mode
    property var item
    property ContactGroupEditor contactGroupEditor: ContactGroupEditor {
        id: contactGroupEditor
        mode: ContactGroupEditor.CreateMode
        onFinished: root.closeDialog()
        onErrorOccured: (error) => {
            errorContainer.text = error;
            errorContainer.visible = true;
        }
        onItemChangedExternally: itemChangedExternallySheet.open()
    }

    title: mode === ContactGroupEditor.EditMode && contactGroupEditor.name ? i18n("Edit %1", contactGroupEditor.name) : i18n("Create Contact Group")

    onItemChanged: contactGroupEditor.loadContactGroup(item)

    function isNotEmptyStr(str) {
        return str.trim().length > 0;
    }

    data: QQC2.Action {
        id: submitAction
        enabled: contactGroupEditor.name.length > 0
        shortcut: "Return"
        onTriggered: {
            contactGroupEditor.saveContactGroup()
            ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
            ContactConfig.save();
        }
    }

    header: Components.Banner {
        id: errorContainer
        type: Kirigami.MessageType.Error
        visible: false
        showCloseButton: true
    }

    FormCard.FormCard {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing

        Akonadi.MobileCollectionComboBox {
            id: addressBookComboBox

            text: i18n("Address Book:")
            Layout.fillWidth: true
            enabled: mode === ContactGroupEditor.CreateMode

            defaultCollectionId: if (mode === ContactGroupEditor.CreateMode) {
                return ContactConfig.lastUsedAddressBookCollection;
            } else {
                return contactGroupEditor.collectionId;
            }

            mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
            accessRightsFilter: Akonadi.Collection.CanCreateItem
            onUserSelectedCollection: collection => contactGroupEditor.setDefaultAddressBook(collection)
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormTextFieldDelegate {
            label: i18n("Name:")
            text: contactGroupEditor.name
            onTextChanged: contactGroupEditor.name = text;
            placeholderText: i18n("Contact group name")
        }
    }

    FormCard.FormHeader {
        title: i18n("Members")
    }

    FormCard.FormCard {
        Repeater {
            id: repeater
            model: contactGroupEditor.groupModel

            delegate: FormCard.AbstractFormDelegate {
                id: contactDelegate

                required property int index
                required property string displayName
                required property string email

                background: null
                contentItem: RowLayout {
                    QQC2.TextField {
                        text: contactDelegate.displayName
                        enabled: false
                        Layout.fillWidth: true
                        Layout.maximumWidth: Math.round(0.4 * parent.width)
                    }
                    QQC2.TextField {
                        text: contactDelegate.email
                        enabled: false
                        Layout.fillWidth: true
                    }
                    QQC2.Button {
                        icon.name: 'list-remove'
                        onClicked: contactGroupEditor.groupModel.removeContact(index)
                    }
                }
            }
        }

        FormCard.AbstractFormDelegate {
            background: null
            contentItem: RowLayout {
                QQC2.ComboBox {
                    id: nameSearch
                    property string gid: ''
                    textRole: 'display'
                    valueRole: 'gid'
                    model: ContactsModel {}
                    editable: true
                    onCurrentIndexChanged: {
                        gid = nameSearch.model.data(nameSearch.model.index(currentIndex, 0), ContactsModel.GidRole);
                        const allEmail = nameSearch.model.data(nameSearch.model.index(currentIndex, 0), ContactsModel.AllEmailsRole);
                        const preferredEmail = nameSearch.model.data(nameSearch.model.index(currentIndex, 0), ContactsModel.EmailRole);
                        emailSearch.currentIndex = emailSearch.indexOfValue(preferredEmail);
                        emailSearch.model = allEmail;
                    }
                    Layout.fillWidth: true
                    Layout.maximumWidth: Math.round(0.4 * parent.width)
                }
                QQC2.ComboBox {
                    id: emailSearch
                    enabled: model.length !== 0
                    model: []
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    icon.name: 'list-add'
                    enabled: emailSearch.currentIndex > 0 || (emailSearch.editText.length > 0 && nameSearch.editText.length > 0)
                    onClicked: {
                        contactGroupEditor.groupModel.addContactFromReference(nameSearch.gid, emailSearch.currentValue)
                        emailSearch.editText = '';
                        nameSearch.editText = '';
                        emailSearch.currentIndex = -1;
                    }
                }
            }
        }

        FormCard.FormTextDelegate {
            description: i18n("Only contacts with an email address can be added to a contact group")
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            icon.name: mode === ContactGroupEditor.EditMode ? "document-save" : "list-add"
            text: mode === ContactGroupEditor.EditMode ? i18n("Save") : i18n("Add")
            enabled: isNotEmptyStr(contactGroupEditor.name)
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
        }

        onRejected: {
            ContactConfig.lastUsedAddressBookCollection = addressBookComboBox.defaultCollectionId;
            ContactConfig.save();
            root.closeDialog();
        }
        onAccepted: submitAction.trigger()
    }

    property QQC2.Dialog itemChangedExternallySheet: QQC2.Dialog {
        id: itemChangedExternallySheet
        visible: false
        title: i18n("Warning")
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: parent.height / 3
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 20)

        contentItem: ColumnLayout {
            Kirigami.Heading {
                level: 4
                text: i18n("This contact group was changed elsewhere during editing.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: i18n("Which changes should be kept?")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        onRejected: itemChangedExternallySheet.close()
        onAccepted: {
            contactGroupEditor.fetchItem();
            itemChangedExternallySheet.close();
        }

        footer: QQC2.DialogButtonBox {
            QQC2.Button {
                text: i18n("Current changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            QQC2.Button {
                text: i18n("External changes")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
            }
        }
    }
}
