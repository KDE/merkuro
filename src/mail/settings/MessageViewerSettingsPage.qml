// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

pragma ComponentBehavior: Bound

import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.merkuro.mail
import org.kde.ki18n

FormCard.FormCardPage {
    title: KI18n.i18nc("@title", "Message Viewer")

    FormCard.FormHeader {
        title: KI18n.i18nc("@title:group", "Message Display")
    }

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            id: preferHtml

            text: KI18n.i18nc("@option:check", "Prefer HTML to plain text")
            checked: Config.preferHtml
            enabled: !Config.isPreferHtmlImmutable
            onToggled: {
                Config.preferHtml = preferHtml.checked;
                Config.save();
            }
        }
    }
}
