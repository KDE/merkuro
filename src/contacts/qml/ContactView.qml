// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact
import org.kde.merkuro.components
import org.kde.kirigamiaddons.components as Components
import org.kde.akonadi as Akonadi
import './private'
import org.kde.ki18n

Kirigami.ScrollablePage {
    id: root

    objectName: "contactView"

    property var attendeeAkonadiIds
    property var contactsModel: ContactManager.filteredContacts
    property var activeContextMenu

    title: KI18n.i18n("Contacts")

    actions: Kirigami.Action {
        icon.name: 'contact-new-symbolic'
        text: KI18n.i18nc("@action:inmenu", "Create")
        Kirigami.Action {
            id: createNewContactAction
            text: KI18n.i18nc("@action:inmenu", "New Contact")
            onTriggered: root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(Qt.resolvedUrl("./private/contact_editor/ContactEditorPage.qml"), {
                mode: ContactEditor.CreateMode,
            })
        }
        Kirigami.Action {
            id: createNewContactGroupAction
            text: KI18n.i18nc("@action:inmenu", "New Contact Group")
            onTriggered: root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(Qt.resolvedUrl("./private/contact_editor/ContactGroupEditorPage.qml"), {
                mode: ContactGroupEditor.CreateMode,
            })
        }
    }

    Connections {
        target: ContactApplication

        function onCreateNewContact(): void {
            createNewContactAction.trigger();
        }

        function onCreateNewContactGroup(): void {
            createNewContactGroupAction.trigger();
        }
    }

    header: QQC2.Pane {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        visible: contactSelectionModel.hasSelection
        height: visible ? implicitHeight : 0

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            ColoredCheckbox {
                id: checkbox
                checked: true
                onToggled: if (!checked) {
                    contactSelectionModel.clear()
                }
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                indicator {
                    implicitWidth: Kirigami.Units.gridUnit
                    implicitHeight: Kirigami.Units.gridUnit
                }
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.largeSpacing
            }

            Kirigami.Heading {
                text: KI18n.i18ncp("Number of selected contacts", "%1 selected", "%1 selected", contactSelectionModel.selectedIndexes.length)
                level: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

    ItemSelectionModel {
        id: contactSelectionModel
        model: contactsList.model
    }

    ContactImportExport {
        id: contactImportExport
        model: root.contactsModel
        selectionModel: contactSelectionModel

        onImportFinished: (success, count, errorMessage) => {
            if (success) {
                root.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18ncp("%1 is the number of imported contacts", "%1 contact imported successfully.", "%1 contacts imported successfully.", count), "short");
            } else {
                root.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18n("Could not import contacts: %1", errorMessage), "long");
            }
        }

        onExportFinished: (success, count, errorMessage) => {
            if (success) {
                root.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18ncp("%1 is the number of exported contacts", "%1 contact exported successfully.", "%1 contacts exported successfully.", count), "short");
            } else {
                root.QQC2.ApplicationWindow.window.showPassiveNotification(KI18n.i18n("Could not export contacts: %1", errorMessage), "long");
            }
        }
    }

    Connections {
        target: ContactApplication

        function onImportContactsRequested(): void {
            if (!contactImportExport.importInProgress) {
                importFileDialog.open();
            }
        }

        function onExportContactsRequested(): void {
            exportFileDialog.open();
        }
    }

    FileDialog {
        id: importFileDialog
        title: KI18n.i18n("Import contacts")
        nameFilters: [KI18n.i18n("vCard files (*.vcf *.vcard)")]

        onAccepted: {
            const component = Qt.createComponent("org.kde.akonadi", "CollectionChooserPage");
            const page = root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                configGroup: "contact-collection-chooser-import",
                title: KI18n.i18n("Import Contacts To:"),
                mimeTypeFilter: [Akonadi.MimeTypes.address],
            });
            page.selected.connect(collection => {
                contactImportExport.importContacts(importFileDialog.selectedFile, collection.id);
                page.closeDialog();
            });
            page.rejected.connect(() => page.closeDialog());
        }
    }

    FileDialog {
        id: exportFileDialog
        title: KI18n.i18n("Export contacts")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "vcf"
        nameFilters: [KI18n.i18n("vCard files (*.vcf)")]

        onAccepted: contactImportExport.exportContacts(exportFileDialog.selectedFile)
    }

    ContactActions {
        id: contactActions
        selectionModel: contactSelectionModel
        contactApplication: ContactApplication

        onMoveToRequested: items => {
            const component = Qt.createComponent("org.kde.akonadi", "CollectionChooserPage");
            const page = root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                configGroup: 'contact-collection-chooser-move',
                title: KI18n.i18nc("@title:dialog", "Move Selection To:"),
                mimeTypeFilter: [Akonadi.MimeTypes.address],
            });

            page.selected.connect(collection => {
                contactActions.moveTo(items, collection);
                page.closeDialog();
            });
            page.rejected.connect(() => {
                page.closeDialog();
            });
        }

        onCopyToRequested: items => {
            const component = Qt.createComponent("org.kde.akonadi", "CollectionChooserPage");
            const page = root.QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(component, {
                configGroup: 'contact-collection-chooser-move',
                title: KI18n.i18nc("@title:dialog", "Copy Selection To:"),
                mimeTypeFilter: [Akonadi.MimeTypes.address],
            });
            page.selected.connect((collection) => {
                contactActions.copyTo(items, collection);
                page.closeDialog();
            });
            page.rejected.connect(() => {
                page.closeDialog();
            });
        }

        onEditContact: (itemId) => {
            const page = applicationWindow().pageStack.push(Qt.resolvedUrl('./private/ContactPage.qml'), {
                itemId,
            })
            page.openEditor();
        }

        onEditContactGroup: (itemId) => {
            const page = applicationWindow().pageStack.push(Qt.resolvedUrl('./private/ContactGroupPage.qml'), {
                itemId,
            })
            page.openEditor();
        }

        onDeleteRequested: (items, names) => {
            const component = Qt.createComponent(Qt.resolvedUrl('./private/DeleteContactDialog.qml'));
            if (component.status === Component.Error) {
                console.error(component.errorString);
                return
            }

            const dialog = component.createObject(root, {
                items,
                names,
            });
            dialog.open();
        }
    }

    function showContextMenu(index: int): void {
        contactSelectionModel.setCurrentIndex(contactSelectionModel.model.index(index, 0), ItemSelectionModel.Current);
        contactActions.setActionState();

        const menu = contextMenu.createObject(root);
        root.activeContextMenu = menu;
        menu.popup();

        menu.closed.connect(() => {
            root.activeContextMenu = null;
            contactSelectionModel.setCurrentIndex(contactSelectionModel.model.index(contactsList.currentIndex, 0), ItemSelectionModel.Current);
        })
    }

    Component {
        id: contextMenu
        Components.ConvergentContextMenu {
            objectName: "contactContextMenu"

            Kirigami.Action {
                fromQAction: ContactApplication.action('contact_edit')
            }

            Kirigami.Action {
                fromQAction: ContactApplication.action('contact_delete')
            }

            Kirigami.Action {
                fromQAction: ContactApplication.action('contact_move_to')
            }

            Kirigami.Action {
                fromQAction: ContactApplication.action('contact_copy_to')
            }
        }
    }

    ListView {
        id: contactsList
        objectName: "contactsList"
        reuseItems: true
        section {
            property: "display"
            criteria: ViewSection.FirstCharacter
            delegate: Kirigami.ListSectionHeader {
                required property string section

                text: section.trim().length > 0 ? section : KI18n.i18nc("Placeholder", "No Name")
            }
        }
        clip: true
        model: root.contactsModel
        delegate: ContactListItem {
            id: contactListItem
            objectName: "contactListItem"

            selectionModel: contactSelectionModel

            onClicked: if (contactListItem.mimeType === 'application/x-vnd.kde.contactgroup') {
                contactSelectionModel.setCurrentIndex(contactSelectionModel.model.index(contactListItem.index, 0), ItemSelectionModel.Current);
                contactsList.currentIndex = index;
                applicationWindow().pageStack.push(Qt.resolvedUrl('./private/ContactGroupPage.qml'), {
                    itemId: contactListItem.itemId,
                });
            } else {
                contactSelectionModel.setCurrentIndex(contactSelectionModel.model.index(contactListItem.index, 0), ItemSelectionModel.Current);
                contactsList.currentIndex = index;
                applicationWindow().pageStack.push(Qt.resolvedUrl('./private/ContactPage.qml'), {
                    itemId: contactListItem.itemId,
                });
            }

            onCreateContextMenu: {
                root.showContextMenu(contactListItem.index)
            }
        }

        Kirigami.PlaceholderMessage {
            objectName: "noContactsPlaceholder"
            anchors.centerIn: parent
            text: KI18n.i18n("No contacts")
            visible: contactsList.count === 0
        }
    }
}
