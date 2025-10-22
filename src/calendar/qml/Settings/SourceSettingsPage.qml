// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.merkuro.calendar
import org.kde.akonadi

import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: root

    title: i18n("Accounts")

    FormCard.FormHeader {
        title: root.title
    }

    AgentConfigurationForm {
        mimetypes: [MimeTypes.calendar, MimeTypes.todo]
        addPageTitle: i18n("Add New Calendar Source…")
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
        types: ["caldav"]
    }
}
