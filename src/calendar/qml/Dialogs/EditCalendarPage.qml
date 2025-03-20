// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.coreaddons

import org.kde.akonadi as Akonadi

import org.kde.merkuro.calendar as Calendar

FormCard.FormCardPage {
    id: root

    title: i18nc("@title", "Edit Calendar")

    property int collectionId
    property Akonadi.collection collection: Calendar.CalendarManager.getCollection(collectionId)
    onCollectionChanged: console.warn("colle change")

    FormCard.FormHeader {
        title: i18nc("@title", "General")
    }
    FormCard.FormCard {
        FormCard.FormTextFieldDelegate {
            id: displayNameField
            text: root.collection.displayName
            label: i18nc("@label:textbox", "Name")
        }
        FormCard.FormIconDelegate {
            id: iconField
            text: i18nc("@label:textbox", "Icon")
            iconName: root.collection.iconName
        }
        FormCard.FormButtonDelegate {
            text: i18nc("@action:button", "Save")
            onClicked: {
                root.collection.displayName = displayNameField.text;
                root.collection.iconName = iconField.text;
                root.collection.saveChanges();
                console.warn("collection:", root.collection)
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
            checked: root.collection.cachePolicy.inheritFromParent
            onCheckedChanged: {
                root.collection.cachePolicy.inheritFromParent = checked;
                root.collection.saveChanges();
            }
        }
        FormCard.FormCheckDelegate {
            text: i18nc("@option:check", "Synchronize when selecting this folder")
            checked: root.collection.cachePolicy.syncOnDemand
            onCheckedChanged: {
                root.collection.cachePolicy.syncOnDemany = checked;
                root.collection.saveChanges();
            }
            enabled: !useParent.checked
        }
        FormCard.FormSpinBoxDelegate {
            label: i18nc("@label:spinbox", "Synchronize after")
            value: root.collection.cachePolicy.intervalCheckTime
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
                if (value === 0) {
                    root.collection.cachePolicy.intervalCheckTime = -1
                } else {
                    root.collection.cachePolicy.intervalCheckTime = value
                }
                root.collection.saveChanges();
            }
            stepSize: 1
            from: 0
        }
    }
}
