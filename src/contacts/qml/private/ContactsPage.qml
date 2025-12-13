/*
 * SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
 * SPDX-FileCopyrightText: 2019 Linus Jahn <lnj@kaidan.im>
 * SPDX-FileCopyrightText: 2019 Jonah Brüchert <jbb@kaidan.im>
 * SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami
import org.kde.merkuro.contact

Kirigami.ScrollablePage {
    id: root

    title: i18n("Contacts")

    property alias contactDelegate: contactsList.delegate
    readonly property alias selectionModel: contactSelectionModel

    header: Controls.Control {
        contentItem: Kirigami.SearchField {
            id: searchField
            onTextChanged: root.model.setFilterFixedString(text)
        }
    }
    property alias model: contactsList.model

    ItemSelectionModel {
        id: contactSelectionModel
        model: contactsList.model
    }

    ListView {
        id: contactsList

        reuseItems: true
        currentIndex: -1

        section {
            property: "display"
            criteria: ViewSection.FirstCharacter
            delegate: Kirigami.ListSectionHeader {
                required property string section
                text: section.trim().length > 0 ? section : i18nc("Placeholder", "No Name")
            }
        }

        clip: true
        model: ContactsModel {}

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            text: i18n("No contacts")
            visible: contactsList.count === 0
        }
    }
}
