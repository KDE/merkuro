// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.components as Components
import QtQuick.Templates as T

QQC2.Dialog {
    id: root

    required property var application

    parent: applicationWindow().overlay
    modal: true

    width: Math.min(700, parent.width)
    height: 400

    leftPadding: 1
    rightPadding: 1
    bottomPadding: 1
    topPadding: 0

    anchors.centerIn: applicationWindow().overlay

    background: Components.DialogRoundedBackground {}

    onOpened: {
        searchField.forceActiveFocus();
        searchField.text = root.application.actionsModel.filterString; // set the previous searched text on reopening
        searchField.selectAll(); // select entire text
    }

    header: T.Control {
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                implicitContentHeight + topPadding + bottomPadding)

        padding: Kirigami.Units.smallSpacing

        contentItem: Kirigami.SearchField {
            id: searchField
            KeyNavigation.down: actionList
            onTextChanged: root.application.actionsModel.filterString = text
        }

        // header background
        background: Kirigami.ShadowedRectangle {
            corners {
                topLeftRadius: Kirigami.Units.smallSpacing
                topRightRadius: Kirigami.Units.smallSpacing
            }
            color: "transparent"

            Kirigami.Separator {
                id: headerSeparator
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: 1
            }
        }
    }

    contentItem: QQC2.ScrollView {
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        background: Kirigami.ShadowedRectangle {
            color: Kirigami.Theme.backgroundColor
            corners {
                bottomLeftRadius: Kirigami.Units.smallSpacing
                bottomRightRadius: Kirigami.Units.smallSpacing
            }
        }

        ListView {
            id: actionList

            Keys.onPressed: if (event.text.length > 0) {
                searchField.forceActiveFocus();
                searchField.text += event.text;
            }

            clip: true

            model: root.application.actionsModel
            delegate: Delegates.RoundedItemDelegate {
                id: commandDelegate

                required property int index
                required property string decoration
                required property string displayName
                required property string shortcut
                required property var qaction

                icon.name: decoration
                text: displayName

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Delegates.DefaultContentItem {
                        itemDelegate: commandDelegate
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: commandDelegate.shortcut
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                onClicked: {
                    qaction.trigger()
                    root.close()
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                text: i18n("No results found")
                visible: actionList.count === 0
                width: parent.width - Kirigami.Units.gridUnit * 4
            }
        }
    }
}
