// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.platform

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.coreaddons

import org.kde.akonadi as Akonadi

import org.kde.merkuro.calendar as Calendar

FormCard.FormCardPage {
    id: root

    title: i18nc("@title", "Edit Calendar")

    required property var collection

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
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button", "Set calendar color…")
            icon.name: "color-management"
            onClicked: {
                colorDialogLoader.active = true;
                colorDialogLoader.item.open();
            }
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
                    return i18nc("As in 'Never synchronize this calendar'", "Never")
                }
                return i18ncp("Interval for updating a calendar", "%1 minute", "%1 minutes", value)
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

    Loader {
        id: colorDialogLoader
        active: false
        sourceComponent: ColorDialog {
            id: colorDialog
            title: i18nc("@title:window", "Choose Calendar Color")
            color: Calendar.CalendarManager.getCollectionDetails(root.collection.id).color //TODO
            onAccepted: Calendar.CalendarManager.setCollectionColor(root.collection.id, color)
            onRejected: {
                close();
                colorDialogLoader.active = false;
            }
        }
    }
}
