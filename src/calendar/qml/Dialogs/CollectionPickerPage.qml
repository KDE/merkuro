// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels 1.0
import org.kde.kitemmodels 1.0
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigamiaddons.delegates 1.0 as Delegates
import org.kde.kirigamiaddons.treeview 1.0 as Tree

import org.kde.merkuro.calendar 1.0 as Calendar

Kirigami.ScrollablePage {
    id: collectionPickerSheet
    title: switch (mode) {
    case Calendar.CalendarApplication.Todo:
        return i18n("Choose a Task Calendar");
    case Calendar.CalendarApplication.Event:
        return i18n("Choose a Calendar");
    case Calendar.CalendarApplication.Contact:
        return i18n("Choose an Address Book");
    default:
        return 'BUG';
    }

    signal cancel
    signal collectionPicked(int collectionId)

    property int mode: Calendar.CalendarApplication.Event

    ListView {
        id: collectionsList

        implicitWidth: Kirigami.Units.gridUnit * 30
        currentIndex: -1

        model: KDescendantsProxyModel {
            id: treeModel

            model: Akonadi.CollectionPickerModel {
                id: collectionPickerModel
                mimeTypeFilter: switch (collectionPickerSheet.mode) {
                case Calendar.CalendarApplication.Todo:
                    return [Akonadi.MimeTypes.todo];
                case Calendar.CalendarApplication.Event:
                    return [Akonadi.MimeTypes.calendar];
                case Calendar.CalendarApplication.Contact:
                    return [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup];
                }
                excludeVirtualCollections: true

                accessRightsFilter: Akonadi.Collection.CanCreateItem
            }
        }

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
                            model: treeModel
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

                    onClicked: treeModel.toggleChildren(index)
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
                            model: treeModel
                        }
                    ]

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

                        Rectangle {
                            anchors.margins: Kirigami.Units.smallSpacing
                            color: model.collectionColor
                            radius: width
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        }
                    }

                    onClicked: collectionPickerSheet.collectionPicked(collectionId);
                }
            }
        }
    }

    footer: QQC2.ToolBar {
        width: parent.width

        contentItem: QQC2.DialogButtonBox {
            padding: 0

            standardButtons: QQC2.DialogButtonBox.Cancel

            onRejected: cancel()
        }
    }
}
