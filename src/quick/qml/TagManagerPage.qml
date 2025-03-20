// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.akonadi as Akonadi
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.ScrollablePage {
    id: root

    title: i18n("Manage Tags")

    Components.MessageDialog {
        id: deleteConfirmSheet

        property string tagName
        property var tag

        parent: root

        title: i18nc("@title:dialog", "Confirm Tag Deletion")
        dialogType: Components.MessageDialog.Warning

        contentItem: QQC2.Label {
            text: i18n("Are you sure you want to delete tag <b>%1</b>?", deleteConfirmSheet.tagName) + " " + i18n("You won't be able to revert this action.")
            wrapMode: Text.Wrap
        }

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel

        onAccepted: {
            Akonadi.TagManager.deleteTag(deleteConfirmSheet.tag);
            deleteConfirmSheet.close();
        }
        onRejected: deleteConfirmSheet.close()
    }

    ListView {
        currentIndex: -1
        model: Akonadi.TagManager.tagModel

        delegate: Delegates.RoundedItemDelegate {
            id: tagDelegate

            required property int index
            required property string name
            required property var tag

            property bool editMode: false

            contentItem: RowLayout {
                id: delegateLayout

                QQC2.Label {
                    Layout.fillWidth: true
                    text: tagDelegate.name
                    visible: !tagDelegate.editMode
                    wrapMode: Text.Wrap
                }

                QQC2.ToolButton {
                    icon.name: "edit-rename"
                    onClicked: tagDelegate.editMode = true
                    visible: !tagDelegate.editMode
                }

                QQC2.ToolButton {
                    icon.name: "delete"
                    onClicked: {
                        deleteConfirmSheet.tag = tagDelegate.tag;
                        deleteConfirmSheet.tagName = tagDelegate.name;
                        deleteConfirmSheet.open();
                    }
                    visible: !tagDelegate.editMode
                }

                QQC2.TextField {
                    id: tagNameField
                    Layout.fillWidth: true
                    text: tagDelegate.name
                    visible: tagDelegate.editMode
                    wrapMode: Text.Wrap
                }

                QQC2.ToolButton {
                    icon.name: "gtk-apply"
                    visible: tagDelegate.editMode
                    onClicked: {
                        Akonadi.TagManager.renameTag(tagDelegate.tag, tagNameField.text)
                        tagDelegate.editMode = false;
                    }
                }

                QQC2.ToolButton {
                    icon.name: "gtk-cancel"
                    onClicked: {
                        tagDelegate.editMode = false;
                        tagNameField.text = tagDelegate.name
                    }
                    visible: tagDelegate.editMode
                }
            }
        }
    }

    footer: QQC2.ToolBar {
        background: Rectangle {
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window

            color: Kirigami.Theme.backgroundColor

            Kirigami.Separator {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
            }
        }

        contentItem: RowLayout {
            QQC2.TextField {
                id: newTagField

                placeholderText: i18n("Create a New Tag…")
                maximumLength: 50
                onAccepted: addTagButton.click()
                background: null

                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                id: addTagButton
                icon.name: "tag-new"
                text: i18n("Quickly Add a New Tag.")
                display: QQC2.ToolButton.IconOnly

                onClicked: if (newTagField.text.length > 0) {
                    Akonadi.TagManager.createTag(newTagField.text.replace(/\r?\n|\r/g, " "));
                    newTagField.text = "";
                }

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
