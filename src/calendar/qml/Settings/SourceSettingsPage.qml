// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.merkuro.calendar 1.0
import org.kde.akonadi 1.0

Kirigami.ScrollablePage {
    id: sourcesSettingsPage

    title: i18n("Accounts")

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    ColumnLayout {
        spacing: 0

        MobileForm.FormHeader {
            title: root.title
            title: i18n("Calendars")

            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        AgentConfigurationForm {
            mimetypes: [MimeTypes.calendar, MimeTypes.todo]
            addPageTitle: i18n("Add New Calendar Source…")

            Layout.fillWidth: true
        }
    }
}
