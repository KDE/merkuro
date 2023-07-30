// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm
import org.kde.akonadi 1.0
import org.kde.kleo 1.0 as Kleo

MobileForm.FormCard {
    id: root

    required property IdentityEditorBackend identityEditorBackend

    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.largeSpacing

    contentItem: ColumnLayout {
        spacing: 0

        MobileForm.FormCardHeader {
            title: i18n("Cryptography")
        }

        Kleo.MobileFormKeyComboBoxDelegate {
            text: i18n("OpenPGP key")
        }
    }
}