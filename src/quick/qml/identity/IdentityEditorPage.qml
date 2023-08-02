// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0

Kirigami.ScrollablePage {
    id: root

    property alias mode: backend.mode
    property alias identityUoid: backend.identityUoid

    required property bool allowDelete
    required property string identityName

    readonly property IdentityEditorBackend backend: IdentityEditorBackend {
        id: backend
        mode: IdentityEditorBackend.CreateMode
    }

    QQC2.Action {
        id: submitAction
        enabled: !root.backend.identity.isNull
        shortcut: "Return"
        onTriggered: {
            root.backend.saveIdentity();
            root.closeDialog();
        }
    }

    title: if (mode === IdentityEditorBackend.CreateMode) {
        return i18n("Add Identity");
    } else {
        return i18n("Edit Identity");
    }

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

    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        BasicIdentityEditorCard {
            identityEditorBackend: backend
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
                icon.name: "delete"
                text: i18n("Delete")
                visible: root.mode === IdentityEditorBackend.EditMode
                enabled: root.allowDelete
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.DestructiveRole
            }

            QQC2.Button {
                icon.name: root.mode === IdentityEditorBackend.EditMode ? "document-save" : "list-add"
                text: root.mode === IdentityEditorBackend.EditMode ? i18n("Save") : i18n("Add")
                QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
            }

            onRejected: root.closeDialog()
            onAccepted: submitAction.trigger();
            onDiscarded: {
                dialogLoader.active = true;
                dialogLoader.item.open();
            }

            Loader {
                id: dialogLoader
                sourceComponent: Kirigami.PromptDialog {
                    id: dialog
                    title: i18n("Delete %1", root.identityName)
                    subtitle: i18n("Are you sure you want to delete this identity?")
                    standardButtons: Kirigami.Dialog.NoButton

                    customFooterActions: [
                        Kirigami.Action {
                            text: i18n("Delete")
                            iconName: "delete"
                            onTriggered: {
                                IdentityUtils.removeIdentity(root.identityName);
                                dialog.close();
                            }
                        },
                        Kirigami.Action {
                            text: i18n("Cancel")
                            iconName: "dialog-cancel"
                            onTriggered: dialog.close()
                        }
                    ]
                }
            }
        }
    }
}