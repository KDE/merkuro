// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.akonadi as Akonadi
import org.kde.merkuro.mail

QQC2.Menu {
    id: mailActionsPopup
    z: 1000

    required property var collectionId
    required property string name
    required property string resourceIdentifier
    readonly property Akonadi.AgentConfiguration agentConfiguration: Akonadi.AgentConfiguration {
        mimetypes: Akonadi.MimeTypes.mail
    }

    QQC2.MenuItem {
        icon.name: "folder-new"
        text: i18n("Add Folder")
        action: NewFolderAction {
            index: mailActionsPopup.collectionId
        }
    }
    QQC2.MenuItem {
        icon.name: "edit-delete"
        text: i18n("Delete Folder")
        action: DeleteFolderAction {
            index: mailActionsPopup.collectionId
            name: mailActionsPopup.name
        }
        enabled: mailActionsPopup.collectionId ? CollectionUtils.isRemovable(mailActionsPopup.collectionId) : false
    }
    QQC2.MenuItem {
        icon.name: "settings-configure"
        text: i18nc("@action:inmenu", "Folder Properties")
        onClicked: MailManager.editCollection(mailActionsPopup.collectionId);
    }

    QQC2.MenuSeparator {
    }

    QQC2.MenuItem {
        icon.name: "view-refresh"
        text: i18nc("@action:inmenu", "Restart Account")
        onClicked: MailManager.updateCollection(mailActionsPopup.collectionId);
    }

    QQC2.MenuItem {
        icon.name: "settings-configure"
        text: i18nc("@action:inmenu", "Account Settings")
        onClicked: mailActionsPopup.agentConfiguration.editIdentifier(mailActionsPopup.resourceIdentifier);
    }
}
