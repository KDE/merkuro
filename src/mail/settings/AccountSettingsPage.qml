// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.akonadi as Akonadi
import org.kde.akonadi.mime as AkonadiMime
import org.kde.kidentitymanagement as KIdentityManagement
import org.kde.merkuro.mail

FormCard.FormCardPage {
    id: accountsSettingsPage

    FormCard.FormHeader {
        title: i18nc("@action:group", "Identities")
    }

    KIdentityManagement.IdentityConfigurationForm {
        cryptographyEditorBackend: IdentityCryptographyEditorBackendFactory.cryptoEditorBackend
    }

    FormCard.FormHeader {
        title: i18nc("@title:group Title for the list of receiving accounts which are imap or pop3 email accounts", "Receiving Accounts")
    }

    Akonadi.AgentConfigurationForm {
        addPageTitle: i18n("Mail Account Configuration")
        mimetypes: Akonadi.MimeTypes.mail
        specialCollections: AkonadiMime.SpecialMailCollections
    }
}
