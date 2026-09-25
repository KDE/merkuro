// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import Qt.labs.qmlmodels

import org.kde.kirigami as Kirigami
import org.kde.akonadi as Akonadi
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kitemmodels
import org.kde.merkuro.mail
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
            mailList.invokeTrigger(mailList.currentItem);
        }
    }

    onCurrentIndexChanged: stateSaver.currentIndex = currentIndex
    onModelChanged: currentIndex = -1

    property var collectionId: -1
    property string name
    property string resourceIdentifier
    readonly property Kirigami.ApplicationWindow appWindow: mailList.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow
    property MailItemMenu mailActionsPopup: MailItemMenu {
        collectionId: mailList.collectionId
        name: mailList.name
        resourceIdentifier: mailList.resourceIdentifier
    }

    signal folderChosen

    function invokeTrigger(item: var): void {
        item.trigger();
    }

    function moveItemToCollection(source: var, collection: var): void {
        source.moveToCollection(collection);
    }

    delegate: DelegateChooser {
        role: 'kDescendantExpandable'

        DelegateChoice {
            roleValue: true

            Delegates.RoundedTreeDelegate {
                id: categoryHeader

                required property string displayName
                required property var collection
                required property var model

                property bool chosen: false
                property bool showSelected: (categoryHeader.pressed === true || (categoryHeader.highlighted === true && mailList.appWindow.wideScreen))

                function trigger(): void {
                    model.checkState = model.checkState === 0 ? 2 : 0;
                    const index = foldersModel.index(model.index, 0);
                    MailManager.loadMailCollection(foldersModel.mapToSource(index));

                    chosen = true;
                    mailList.folderChosen();
                    mailList.currentIndex = model.index;
                }

                text: displayName
                dropAreaHovered: categoryDropArea.containsDrag

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
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(categoryHeader.model.index, 0));
                            mailList.name = categoryHeader.displayName;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailList.mailActionsPopup.popup()
                        }
                    }
                }

                DropArea {
                    id: categoryDropArea

                    anchors.fill: parent
                    onDropped: (drop) => {
                        mailList.moveItemToCollection(drop.source, categoryHeader.collection);
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
                property bool showSelected: (controlRoot.pressed === true || (controlRoot.highlighted === true && mailList.appWindow.wideScreen))

                text: displayName
                dropAreaHovered: folderDropArea.containsDrag

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
                        source: controlRoot.model.decoration
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

                            mailList.mailActionsPopup.popup();
                        }
                    }
                }

                DropArea {
                    id: folderDropArea

                    anchors.fill: parent
                    onDropped: (drop) => {
                        mailList.moveItemToCollection(drop.source, controlRoot.collection);
                    }
                }
            }
        }
    }
}
