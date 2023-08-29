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

Kirigami.ScrollablePage {
    id: accountsSettingsPage
    title: i18n("Accounts")
    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Account settings")
                }
            }
        }

        MobileForm.FormHeader {
            title: i18n("Identities")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        KIdentityManagement.IdentityConfigurationForm {
            Layout.fillWidth: true
            cryptographyEditorBackend: IdentityCryptographyEditorBackendFactory.newCryptoEditorBackend()
        }

        MobileForm.FormHeader {
            title: i18n("Receiving Accounts")
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
        
        Akonadi.AgentConfigurationForm {
            addPageTitle: i18n("Mail Account Configuration")
            mimetypes: Akonadi.MimeTypes.mail
            Layout.fillWidth: true
        }
    }
}
