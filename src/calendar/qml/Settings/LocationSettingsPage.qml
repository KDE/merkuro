// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.calendar as Calendar

FormCard.FormCardPage {
    title: i18n("Locations")

    FormCard.FormHeader {
        title: i18n("Maps and Location Search")
    }

    FormCard.FormCard {
        autoSeparators: true

        FormCard.FormSwitchDelegate {
            id: enableMaps
            objectName: "enableMapsSwitch"
            text: i18n("Enable maps and location search")
            description: i18n("May cause crashing on some systems.")
            checked: Calendar.Config.enableMaps
            enabled: !Calendar.Config.isEnableMapsImmutable
            onToggled: {
                Calendar.Config.enableMaps = enableMaps.checked;
                Calendar.Config.save();
            }
        }

        FormCard.FormComboBoxDelegate {
            id: locationMarker
            objectName: "locationMarkerCombo"
            text: i18n("Location marker")
            enabled: Calendar.Config.enableMaps && !Calendar.Config.isLocationMarkerImmutable
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Circle (shows area of location)"), value: Calendar.Config.Circle },
                { text: i18n("Pin (shows exact location)"), value: Calendar.Config.Pin }
            ]
            currentIndex: Calendar.Config.locationMarker === Calendar.Config.Circle ? 0 : 1
            onActivated: function(index: int): void {
                Calendar.Config.locationMarker = locationMarker.currentValue;
                Calendar.Config.save();
            }
        }
    }
}
