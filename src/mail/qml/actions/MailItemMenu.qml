// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.14 as Kirigami
import org.kde.akonadi 1.0 as Akonadi
import org.kde.merkuro.mail 1.0

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