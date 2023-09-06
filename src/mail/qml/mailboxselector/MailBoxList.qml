// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import Qt.labs.qmlmodels 1.0

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

            Delegates.RoundedItemDelegate {
                id: categoryHeader

                leftInset: Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + categoryHeader.padding * 2 : 0
                leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + categoryHeader.padding * 2 : 0) + Kirigami.Units.smallSpacing

                rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + categoryHeader.padding * 2 : 0) + Kirigami.Units.smallSpacing
                rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + categoryHeader.padding * 2 : 0) + Kirigami.Units.smallSpacing * 2

                text: model.display

                data: [
                    Tree.TreeViewDecoration {
                        id: decoration
                        anchors {
                            left: parent.left
                            top:parent.top
                            bottom: parent.bottom
                            leftMargin: categoryHeader.padding
                        }
                        parent: categoryHeader
                        parentDelegate: categoryHeader
                        model: foldersModel
                    }
                ]

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
                        text: model.display
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            mailList.model.toggleChildren(index);
                        }
                        if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(index, 0));
                            mailList.name = model.display;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup()
                        }
                    }
                }
            }
        }

        DelegateChoice {
            roleValue: false

            Delegates.RoundedItemDelegate {
                id: controlRoot

                text: model.display

                leftInset: (Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + controlRoot.padding * 2 : 0)
                leftPadding: (Qt.application.layoutDirection !== Qt.RightToLeft ? decoration.width + controlRoot.padding * 2 : 0) + Kirigami.Units.smallSpacing

                rightInset: (Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + controlRoot.padding * 2 : 0) + Kirigami.Units.smallSpacing
                rightPadding: (Qt.application.layoutDirection === Qt.RightToLeft ? decoration.width + controlRoot.padding * 2 : 0) + Kirigami.Units.smallSpacing * 2

                property bool chosen: false

                data: [
                    Tree.TreeViewDecoration {
                        id: decoration
                        anchors {
                            left: parent.left
                            top:parent.top
                            bottom: parent.bottom
                            leftMargin: controlRoot.padding
                        }
                        parent: controlRoot
                        parentDelegate: controlRoot
                        model: foldersModel
                    }
                ]

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
                        property int unreadCount: MailCollectionHelper.unreadCount(model.collection)
                        text: unreadCount > 0 ? unreadCount : ''
                        padding: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.textColor
                        font: Kirigami.Theme.smallFont
                        Layout.minimumWidth: height
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            visible: unreadCount > 0
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
                    onClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            model.checkState = model.checkState === 0 ? 2 : 0
                            MailManager.loadMailCollection(foldersModel.mapToSource(foldersModel.index(model.index, 0)));

                            controlRoot.chosen = true;
                            mailList.folderChosen();
                        }
                        if (mouse.button === Qt.RightButton) {
                            mailList.collectionId = foldersModel.mapToSource(foldersModel.index(model.index, 0));
                            mailList.name = model.display;
                            mailList.resourceIdentifier = MailManager.resourceIdentifier(mailList.collectionId);

                            mailActionsPopup.popup();
                        }
                    }
                }
            }
        }
    }
}