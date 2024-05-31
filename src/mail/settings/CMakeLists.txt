# SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

qt_add_library(mail_settings STATIC)

qt_add_qml_module(mail_settings
    URI org.kde.merkuro.mail.settings
    QML_FILES
        AccountSettingsPage.qml
        Settings.qml
)
