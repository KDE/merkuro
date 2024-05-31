// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard 1 as FormCard
import org.kde.akonadi 1 as Akonadi
import org.kde.kidentitymanagement 1 as KIdentityManagement
import org.kde.merkuro.mail

FormCard.FormCardPage {
    id: accountsSettingsPage

    FormCard.FormHeader {
        title: i18nc("@action:group", "Identities")
        Layout.fillWidth: true
    }

    KIdentityManagement.IdentityConfigurationForm {
        Layout.fillWidth: true
        cryptographyEditorBackend: IdentityCryptographyEditorBackendFactory.cryptoEditorBackend
    }

    FormCard.FormHeader {
        title: i18nc("@title:group Title for the list of receiving accounts which are imap or pop3 email accounts", "Receiving Accounts")
        Layout.fillWidth: true
    }

    Akonadi.AgentConfigurationForm {
        addPageTitle: i18n("Mail Account Configuration")
        mimetypes: Akonadi.MimeTypes.mail
        Layout.fillWidth: true
    }
}
