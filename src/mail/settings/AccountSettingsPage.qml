// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.akonadi as Akonadi
import org.kde.akonadi.mime as AkonadiMime
import org.kde.kidentitymanagement as KIdentityManagement
import org.kde.merkuro.mail
import org.kde.merkuro.mail.settings as MailSettings
import org.kde.ki18n

FormCard.FormCardPage {
    id: accountsSettingsPage

    FormCard.FormHeader {
        title: KI18n.i18nc("@action:group", "Identities")
    }

    KIdentityManagement.IdentityConfigurationForm {
        // The dependency's QML type metadata omits this registered C++ property type.
        // qmllint disable unresolved-type
        cryptographyEditorBackend: IdentityCryptographyEditorBackendFactory.cryptoEditorBackend
        signatureEditorBackend: IdentitySignatureEditorBackendFactory.signatureEditorBackend
        // qmllint enable unresolved-type
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group Title for the list of receiving accounts which are imap or pop3 email accounts", "Receiving Accounts")
    }

    Akonadi.AgentConfigurationForm {
        addPageTitle: KI18n.i18n("Mail Account Configuration")
        mimetypes: Akonadi.MimeTypes.mail
        // The dependency exposes SpecialMailCollections as a derived runtime type.
        // qmllint disable incompatible-type
        specialCollections: AkonadiMime.SpecialMailCollections
        // qmllint enable incompatible-type
    }

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group Title for the list of sending accounts which are SMTP email accounts", "Sending Accounts")
    }

    MailSettings.TransportConfigurationForm {
        addPageTitle: KI18n.i18n("Mail Account Configuration")
    }
}
