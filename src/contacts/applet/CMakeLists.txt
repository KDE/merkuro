# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

find_package(Plasma)

if(Plasma_FOUND)
    plasma_add_applet(org.kde.merkuro.contact.applet
        QML_SOURCES
            qml/CompactRepresentation.qml
            qml/ContactPage.qml
            qml/ContactsPage.qml
            qml/Header.qml
            qml/main.qml
            qml/QrCodePage.qml
        RESOURCES
            main.xml
            fallbackBackground.png
        GENERATE_APPLET_CLASS
    )
endif()
