// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import Qt.labs.qmlmodels

import org.kde.kirigami 2.15 as Kirigami
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigamiaddons.delegates 1.0 as Delegates
import org.kde.kirigamiaddons.treeview 1.0 as Tree
import org.kde.kitemmodels 1.0
import org.kde.merkuro.mail 1.0
import '../actions'

ListView {
    id: mailList

    model: KDescendantsProxyModel {
        id: foldersModel
        model: MailManager.foldersModel
    }

    onModelChanged: currentIndex = -1

    required property var collectionId
    required property string name
    required property string resourceIdentifier
    property MailItemMenu mailActionsPopup: MailItemMenu {
        collectionId: mailList.collectionId
        name: mailList.name
        resourceIdentifier: mailList.resourceIdentifier
    }

    signal folderChosen()

    delegate: DelegateChooser {
        role: 'kDescendantExpandable'

        DelegateChoice {
            roleValue: true

            Delegates.RoundedTreeDelegate {
                id: categoryHeader

                required property string displayName
                required property var model

                property bool chosen: false

                Connections {
                    target: mailList

                    function onFolderChosen() {
                        if (categoryHeader.chosen) {
                            categoryHeader.chosen = false;
                            categoryHeader.highlighted = true;
                        } else {
                            categoryHeader.highlighted = false;
                        }
                    }
                }

                property bool showSelected: (controlRoot.pressed === true || (controlRoot.highlighted === true && applicationWindow().wideScreen))

                text: displayName

                contentItem: RowLayout {
                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        isMask: true
                        source: "folder-symbolic"
                    }

                    QQC2.Label {
                        color: Kirigami.Theme.textColor
                        font.weight: Font.DemiBold
                        text: categoryHeader.displayName
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            categoryHeader.model.checkState = categoryHeader.model.checkState === 0 ? 2 : 0
                            const index = foldersModel.index(categoryHeader.model.index, 0);
                            MailManager.loadMailCollection(foldersModel.mapToSource(index));

                            categoryHeader.chosen = true;
                            mailList.folderChosen();
                        } else if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(index, 0));
                            mailList.name = categoryHeader.displayName;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup()
                        }
                    }
                }
            }
        }

        DelegateChoice {
            roleValue: false

            Delegates.RoundedTreeDelegate {
                id: controlRoot

                required property string displayName
                required property var collection
                required property var model

                property bool chosen: false

                text: displayName

                Connections {
                    target: mailList

                    function onFolderChosen() {
                        if (controlRoot.chosen) {
                            controlRoot.chosen = false;
                            controlRoot.highlighted = true;
                        } else {
                            controlRoot.highlighted = false;
                        }
                    }
                }

                property bool showSelected: (controlRoot.pressed === true || (controlRoot.highlighted === true && applicationWindow().wideScreen))

                contentItem: RowLayout {
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignVCenter
                        source: model.decoration
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Layout.preferredHeight
                    }

                    QQC2.Label {
                        leftPadding: controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0
                        rightPadding: !controlRoot.mirrored ? (controlRoot.indicator ? controlRoot.indicator.width : 0) + controlRoot.spacing : 0

                        text: controlRoot.text
                        font: controlRoot.font
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        visible: controlRoot.text
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        property int unreadCount: MailCollectionHelper.unreadCount(controlRoot.collection)

                        text: unreadCount > 0 ? unreadCount : ''
                        padding: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        Layout.minimumWidth: height
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            visible: parent.unreadCount > 0
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            color: Kirigami.Theme.disabledTextColor
                            opacity: 0.3
                            radius: height / 2
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            controlRoot.model.checkState = controlRoot.model.checkState === 0 ? 2 : 0
                            MailManager.loadMailCollection(foldersModel.mapToSource(foldersModel.index(controlRoot.model.index, 0)));

                            controlRoot.chosen = true;
                            mailList.folderChosen();
                        }
                        if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(controlRoot.model.index, 0));
                            mailList.name = controlRoot.displayName;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup();
                        }
                    }
                }
            }
        }
    }
}
