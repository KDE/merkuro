# SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

qt_add_library(mail_settings STATIC)

qt_add_qml_module(mail_settings
    URI org.kde.merkuro.mail.settings
    DEPENDENCIES
        org.kde.akonadi
        org.kde.akonadi.mime
        org.kde.kidentitymanagement
        org.kde.ki18n
        org.kde.kirigami
        org.kde.kirigamiaddons.components
        org.kde.kirigamiaddons.delegates
        org.kde.kirigamiaddons.formcard
        org.kde.kirigamiaddons.settings
        org.kde.mailtransport
        org.kde.merkuro.mail
    QML_FILES
        AccountSettingsPage.qml
        Settings.qml
        TransportConfigurationForm.qml
)
