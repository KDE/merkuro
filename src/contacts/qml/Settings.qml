// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import org.kde.akonadi 1.0 as Akonadi

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
}
