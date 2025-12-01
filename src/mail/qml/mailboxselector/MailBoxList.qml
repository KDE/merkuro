// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import Qt.labs.qmlmodels

import org.kde.kirigami as Kirigami
import org.kde.akonadi as Akonadi
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.treeview as Tree
import org.kde.kitemmodels
import org.kde.merkuro.mail
import org.kde.merkuro.components
import '../actions'

ListView {
    id: mailList

    model: KDescendantsProxyModel {
        id: foldersModel
        model: MailManager.foldersModel
        expandsByDefault: false
    }

    Akonadi.ETMTreeViewStateSaver {
        id: stateSaver

        model: foldersModel
        configGroup: "mail-sidebar"
        onCurrentIndexChanged: {
            mailList.currentIndex = currentIndex
            mailList.currentItem.trigger();
        }
    }

    onCurrentIndexChanged: stateSaver.currentIndex = currentIndex
    onModelChanged: currentIndex = -1

    required property var collectionId
    required property string name
    required property string resourceIdentifier
    property MailItemMenu mailActionsPopup: MailItemMenu {
        collectionId: mailList.collectionId
        name: mailList.name
        resourceIdentifier: mailList.resourceIdentifier
    }

    signal folderChosen

    delegate: DelegateChooser {
        role: 'kDescendantExpandable'

        DelegateChoice {
            roleValue: true

            Delegates.RoundedTreeDelegate {
                id: categoryHeader

                required property string displayName
                required property var model

                property bool chosen: false
                property bool showSelected: (categoryHeader.pressed === true || (categoryHeader.highlighted === true && applicationWindow().wideScreen))

                function trigger(): void {
                    model.checkState = model.checkState === 0 ? 2 : 0;
                    const index = foldersModel.index(model.index, 0);
                    MailManager.loadMailCollection(foldersModel.mapToSource(index));

                    chosen = true;
                    mailList.folderChosen();
                    mailList.currentIndex = model.index;
                }

                text: displayName
                dropAreaHovered: dropArea.containsDrag

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        source: categoryHeader.model.decoration
                    }

                    QQC2.Label {
                        color: Kirigami.Theme.textColor
                        font.weight: Font.DemiBold
                        text: categoryHeader.displayName
                        Layout.fillWidth: true
                        Accessible.ignored: true
                    }
                }

                Connections {
                    target: mailList

                    function onFolderChosen(): void {
                        if (categoryHeader.chosen) {
                            categoryHeader.chosen = false;
                            categoryHeader.highlighted = true;
                        } else {
                            categoryHeader.highlighted = false;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            categoryHeader.trigger();
                        } else if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(index, 0));
                            mailList.name = categoryHeader.displayName;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup()
                        }
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    onDropped: (drop) => {
                        drop.source.moveToCollection(controlRoot.collection);
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
                required property int unreadCount

                property bool chosen: false
                property bool showSelected: (controlRoot.pressed === true || (controlRoot.highlighted === true && applicationWindow().wideScreen))

                text: displayName
                dropAreaHovered: dropArea.containsDrag

                function trigger(): void {
                    model.checkState = model.checkState === 0 ? 2 : 0;
                    MailManager.loadMailCollection(foldersModel.mapToSource(foldersModel.index(model.index, 0)));

                    chosen = true;
                    mailList.folderChosen();
                    mailList.currentIndex = index;
                }

                Connections {
                    target: mailList

                    function onFolderChosen(): void {
                        if (controlRoot.chosen) {
                            controlRoot.chosen = false;
                            controlRoot.highlighted = true;
                        } else {
                            controlRoot.highlighted = false;
                        }
                    }
                }


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
                        text: controlRoot.unreadCount > 0 ? controlRoot.unreadCount : ''
                        padding: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        Layout.minimumWidth: height
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            visible: controlRoot.unreadCount > 0
                            color: Kirigami.Theme.highlightColor
                            opacity: 0.3
                            radius: width
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            controlRoot.trigger();
                        }
                        if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(controlRoot.model.index, 0));
                            mailList.name = controlRoot.displayName;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup();
                        }
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    onDropped: (drop) => {
                        drop.source.moveToCollection(controlRoot.collection);
                    }
                }
            }
        }
    }
}
