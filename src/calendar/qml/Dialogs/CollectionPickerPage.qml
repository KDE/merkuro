// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts 1.1
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.14 as Kirigami
import Qt.labs.qmlmodels
import org.kde.kitemmodels 1.0
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigamiaddons.delegates 1.0 as Delegates

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

                Delegates.RoundedTreeDelegate {
                    id: categoryHeader

                    required property var model

                    text: model.display

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
                            text: categoryHeader.text
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: treeModel.toggleChildren(model.index)
                }
            }

            DelegateChoice {
                roleValue: false

                Delegates.RoundedTreeDelegate {
                    id: controlRoot

                    required property var model
                    required property var collectionColor
                    required property var collectionId
                    required property string decoration

                    text: model.display

                    contentItem: RowLayout {
                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignVCenter
                            source: controlRoot.decoration
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
                            color: controlRoot.collectionColor
                            radius: width
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        }
                    }

                    onClicked: collectionPickerSheet.collectionPicked(controlRoot.collectionId);
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
