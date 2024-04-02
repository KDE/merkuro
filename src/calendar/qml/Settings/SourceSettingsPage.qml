// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Layouts
import org.kde.merkuro.calendar 1.0
import org.kde.akonadi 1.0

import org.kde.kirigamiaddons.formcard 1.0 as FormCard

FormCard.FormCardPage {
    id: sourcesSettingsPage

    title: i18n("Accounts")

    FormCard.FormHeader {
        title: root.title

        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
    }

    AgentConfigurationForm {
        mimetypes: [MimeTypes.calendar, MimeTypes.todo]
        addPageTitle: i18n("Add New Calendar Source…")

        Layout.fillWidth: true
    }
}
