// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.akonadi as Akonadi
import org.kde.merkuro.components
import org.kde.kitemmodels
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.ScrollablePage {
    id: root

    /**
     * This property holds the mime types of the collection that should be
     * displayed.
     *
     * @property list<string> mimeTypeFilter
     * @code{.qml}
     * import org.kde.akonadi as Akonadi
     * 
     * Akonadi.CollectionChooserPage {
     *     mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
     * }
     * @endcode
     */
    property alias mimeTypeFilter: collectionPickerModel.mimeTypeFilter

    /**
     * This property holds the access right of the collection that should be
     * displayed.
     *
     * @property Akonadi::Collection::Rights rights
     * @code{.qml}
     * import org.kde.akonadi as Akonadi
     * 
     * Akonadi.CollectionChooserPage {
     *     accessRightsFilter: Akonadi.Collection.CanCreateItem
     * }
     * @endcode
     *
     * Default: Akonadi.Collection.CanCreateItem
     */
    property alias accessRightsFilter: collectionPickerModel.accessRightsFilter

    property string configGroup

    signal selected(var collection)
    signal rejected

    ListView {
        id: list

        model: KDescendantsProxyModel {
            id: treeModel

            model: Akonadi.CollectionPickerModel {
                id: collectionPickerModel
                excludeVirtualCollections: true

                accessRightsFilter: Akonadi.Collection.CanCreateItem
            }
            expandsByDefault: false
        }

        ETMTreeViewStateSaver {
            id: stateSaver

            model: list.model
            configGroup: root.configGroup
            onCurrentIndexChanged: {
                list.currentIndex = currentIndex;
            }
        }

        delegate: Delegates.RoundedTreeDelegate {
            id: delegate

            required property string displayName
            required property var model
            required property var collection

            text: displayName

            onClicked: if (kDescendantExpandable) {
                treeModel.toggleChildren(model.index);
            } else {
                list.currentIndex = model.index;
                dialogButtonBox.standardButton(Controls.Dialog.Ok).enabled = true;
            }

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    source: delegate.model.decoration
                }

                Controls.Label {
                    color: Kirigami.Theme.textColor
                    text: delegate.text
                    Layout.fillWidth: true
                    Accessible.ignored: true
                }
            }
        }
    }

    footer: Controls.ToolBar {
        contentItem: Controls.DialogButtonBox {
            id: dialogButtonBox
            standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
            onRejected: root.rejected();
            onAccepted: root.selected(list.currentItem.collection);
            Component.onCompleted: dialogButtonBox.standardButton(Controls.Dialog.Ok).enabled = false;
        }
    }
}
