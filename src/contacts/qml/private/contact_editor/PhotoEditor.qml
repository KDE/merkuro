// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects

import org.kde.kirigami 2 as Kirigami
import org.kde.merkuro.contact

ColumnLayout {
    id: root

    required property ContactEditor contactEditor
    property var loadedPhoto: contactEditor.contact.photo

    Layout.alignment: Qt.AlignHCenter

    Loader {
        id: photoUploadLoader

        active: false
        onLoaded: item.open();

        sourceComponent: FileDialog {
            title: i18n("Select a file")
            nameFilters: [i18n("Images files (*.png *.jpeg *.jpg)")]
            folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
            onAccepted: {
                if (currentFile) {
                    root.loadedPhoto = root.contactEditor.contact.preparePhoto(currentFile);
                    root.contactEditor.contact.updatePhoto(root.loadedPhoto);
                }
                photoUploadLoader.active = false;
            }
            onRejected: photoUploadLoader.active = false
        }
    }

    QQC2.RoundButton {
        Kirigami.FormData.label: i18n("Photo")
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        // Square button
        implicitWidth: Kirigami.Units.gridUnit * 5
        implicitHeight: implicitWidth

        contentItem: Item {
            // Doesn't like to be scaled when being the direct contentItem
            Kirigami.Icon {
                anchors {
                    fill: parent
                    margins: Kirigami.Units.smallSpacing
                }

                layer {
                    enabled: GraphicsInfo.api !== GraphicsInfo.Software
                    effect: OpacityMask {
                        maskSource: mask
                    }
                }

                source: if (root.loadedPhoto.isEmpty) {
                    return "edit-image-face-add"
                } else if (root.loadedPhoto.isIntern) {
                    return root.loadedPhoto.data
                } else {
                    return root.loadedPhoto.url
                }
            }

            Rectangle {
                id: mask
                anchors.fill: parent
                visible: false
                radius: height
            }
        }

        onClicked: photoUploadLoader.active = true
    }

    QQC2.Label {
        text: root.loadedPhoto.isEmpty ? i18n("Add Profile Picture") : i18n("Update Profile Picture")
        color: Kirigami.Theme.disabledTextColor
        Layout.alignment: Qt.AlignHCenter
    }
}
