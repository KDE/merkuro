// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.platform

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.coreaddons
import org.kde.kirigami as Kirigami

import org.kde.akonadi as Akonadi

FormCard.FormCardPage {
    id: root

    required property var collection
    required title
    property list<Kirigami.Action> extraActions: []

    Akonadi.CollectionEditorController {
        id: editor
        collectionId: root.collection.id
    }

    FormCard.FormHeader {
        title: i18nc("@title", "General")
    }
    FormCard.FormCard {
        FormCard.FormTextFieldDelegate {
            id: displayNameField
            text: editor.displayName
            onEditingFinished: if (editor.displayName !== text) {
                editor.displayName = text;
                editor.save();
            }
            label: i18nc("@label:textbox", "Name")
            enabled: root.collection.rights & Akonadi.collection.Right.CanChangeCollection
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormIconDelegate {
            id: iconField
            text: i18nc("@label:textbox", "Icon")
            iconName: editor.iconName
            onIconNameChanged: if (editor.iconName !== iconName) {
                editor.iconName = iconName;
                editor.save();
            }
        }
        FormCard.FormDelegateSeparator {}

        Repeater {
            model: root.extraActions
            delegate: FormCard.FormButtonDelegate {
                required property Kirigami.Action modelData
                text: modelData.text
                icon.name: modelData.icon.name
                onClicked: modelData.triggered()
            }
        }
    }
    FormCard.FormHeader {
        title: i18nc("@title", "Statistics")
    }
    FormCard.FormCard {
        FormCard.FormTextDelegate {
            description: i18ncp("@info", "%1 entry", "%1 entries", root.collection.statistics.count)
            text: i18nc("@label", "Content")
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormTextDelegate {
            description: Format.formatByteSize(root.collection.statistics.size)
            text: i18nc("@label", "Size")
        }
    }
    FormCard.FormHeader {
        title: i18nc("@title", "Retrieval")
    }
    FormCard.FormCard {
        FormCard.FormCheckDelegate {
            id: useParent
            text: i18nc("@option:check", "Use options from parent folder or account")
            checked: editor.cachePolicy.inheritFromParent
            onToggled: {
                editor.cachePolicy.inheritFromParent = checked;
                editor.save();
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormCheckDelegate {
            text: i18nc("@option:check", "Synchronize when selecting this folder")
            checked: editor.cachePolicy.syncOnDemand
            onToggled: {
                editor.cachePolicy.syncOnDemand = checked;
                editor.save();
            }
            enabled: !useParent.checked
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSpinBoxDelegate {
            label: i18nc("@label:spinbox", "Synchronize after")
            value: editor.cachePolicy.intervalCheckTime
            enabled: !useParent.checked
            textFromValue: function(value, locale) {
                if (value === 0) {
                    return i18nc("As in 'Never synchronize this account'", "Never")
                }
                return i18ncp("Interval for updating an account", "%1 minute", "%1 minutes", value)
            }

            valueFromText: function(text, locale) {
                return parseInt(text)
            }
            onValueChanged: {
                if (value === 0 && editor.cachePolicy.intervalCheckTime !== -1) {
                    editor.cachePolicy.intervalCheckTime = -1
                    editor.save();
                } else if (editor.cachePolicy.intervalCheckTime !== value) {
                    editor.cachePolicy.intervalCheckTime = value
                    editor.save();
                }
            }
            stepSize: 1
            from: 0
        }
    }
}
