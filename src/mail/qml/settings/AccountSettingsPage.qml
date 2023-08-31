// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kidentitymanagement 1.0 as KIdentityManagement
import org.kde.merkuro.mail 1.0
import org.kde.kirigamiaddons.formcard 1.0 as FormCard

FormCard.FormCardPage {
    id: accountsSettingsPage

    FormCard.FormHeader {
        title: i18n("Identities")
        Layout.fillWidth: true
    }

    KIdentityManagement.IdentityConfigurationForm {
        Layout.fillWidth: true
        cryptographyEditorBackend: IdentityCryptographyEditorBackendFactory.newCryptoEditorBackend()
    }

    FormCard.FormHeader {
        title: i18n("Receiving Accounts")
        Layout.fillWidth: true
    }
    
    Akonadi.AgentConfigurationForm {
        addPageTitle: i18n("Mail Account Configuration")
        mimetypes: Akonadi.MimeTypes.mail
        Layout.fillWidth: true
    }
}
