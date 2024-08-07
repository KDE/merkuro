// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.merkuro 1.0 as Merkuro
import org.kde.merkuro.contact
import org.kde.akonadi as Akonadi
import './private'

TapHandler {
    id: handler

    property var collection
    property var collectionDetails
    property Akonadi.AgentConfiguration agentConfiguration

    acceptedButtons: Kirigami.Settings.isMobile ? Qt.LeftButton | Qt.RightButton : Qt.RightButton

    onTapped: addressBookActions.createObject(handler, {}).popup();

    onLongPressed: if (Kirigami.Settings.isMobile) {
        addressBookActions.createObject(handler, {}).popup();
    }

    property Loader colorDialogLoader: Loader {
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Address Book Color")
            color: handler.collectionDetails.color
            onAccepted: ContactManager.setCollectionColor(handler.collection, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }

    property Component addressBookActions: Component {
        AddressBookMenu {
            parent: handler.parent

            collection: handler.collection
            collectionDetails: handler.collectionDetails
            agentConfiguration: calendarTapHandler.agentConfiguration
        }
    }
}
