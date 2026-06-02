// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.akonadi as Akonadi

import org.kde.merkuro.components

FormCard.FormCardPage {
    id: root

    title: i18nc("@title:window", "Settings")

    FormCard.FormHeader {
        title: i18n("Contact Books")
    }

    Akonadi.AgentConfigurationForm {
        mimetypes: [Akonadi.MimeTypes.contactGroup, Akonadi.MimeTypes.address]
        addPageTitle: i18n("Add New Address Book Source…")
        Layout.fillWidth: true
    }

    FormCard.FormHeader {
        title: i18n("System Accounts")

        visible: systemAccountsForm.available

        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
    }

    SystemAccountsForm {
        id: systemAccountsForm

        visible: available

        Layout.fillWidth: true
        types: ["carddav", "google"]
    }

}
