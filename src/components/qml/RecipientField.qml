// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.merkuro.components

QQC2.SearchField {
    id: root

    suggestionModel: completion.suggestions

    delegate: Delegates.RoundedItemDelegate {
        id: suggestionDelegate

        required property int index
        required property string modelData

        text: suggestionDelegate.modelData
        highlighted: root.highlightedIndex === suggestionDelegate.index
    }

    onTextChanged: {
        if (text.length === 0) {
            completion.searchText = "";
        }
    }
    onTextEdited: completion.searchText = text
    onSuggestionCountChanged: {
        if (suggestionCount > 0 && activeFocus && text.length > 0) {
            popup.open();
        } else {
            popup.close();
        }
    }
    onActivated: function(index: int): void {
        completion.searchText = "";
    }
    onActiveFocusChanged: {
        if (!activeFocus) {
            completion.searchText = "";
        }
    }

    RecipientCompletion {
        id: completion
    }
}
