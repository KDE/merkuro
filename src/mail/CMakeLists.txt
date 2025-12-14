# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(settings)

set(merkuro_mail_SRCS
    abstractmailmodel.cpp
    abstractmailmodel.h
    mailactions.cpp
    mailactions.h
    mailapplication.cpp
    mailapplication.h
    mailmanager.cpp
    mailmanager.h
    mailmodel.cpp
    mailmodel.h
    searchmodel.h
    searchmodel.cpp
    contactimageprovider.cpp
    contactimageprovider.h
    progressmodel.cpp
    progressmodel.h

    messageloader.h
    messageloader.cpp

    mailkernel.h
    mailkernel.cpp

    mailheadermodel.h
    mailheadermodel.cpp

    mailclient.h
    mailclient.cpp

    identity/identitycryptographybackend.h
    identity/identitycryptographybackend.cpp
    identity/identitycryptographyeditorbackendfactory.h
    identity/identitycryptographyeditorbackendfactory.cpp
    identity/identitykeylistmodel.h
    identity/identitykeylistmodel.cpp

    messagehandler.cpp
    messagehandler.h

    attachmentmodel.cpp
    attachmentmodel.h
)

ecm_qt_declare_logging_category(merkuro_mail_SRCS
    HEADER merkuro_mail_debug.h
    IDENTIFIER "MERKURO_MAIL_LOG"
    CATEGORY_NAME org.kde.merkuro.mail
    DESCRIPTION "merkuro mail"
    EXPORT merkuro
)

add_library(merkuro_mail_static STATIC ${merkuro_mail_SRCS})
target_include_directories(merkuro_mail_static PUBLIC identity)
kconfig_add_kcfg_files(merkuro_mail_static GENERATE_MOC mailconfig.kcfgc)
set_target_properties(merkuro_mail_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(merkuro_mail_static
    PUBLIC
        KPim6::MessageComposer
        KPim6::MailCommon
        KPim6::MailTransport
        KPim6::AkonadiMime
        KPim6::AkonadiSearchPIM
        KPim6::IdentityManagementQuick
        KPim6::Mbox
        KPim6::Mime
        KPim6::Libkdepim
        KPim6::PimCommonAkonadi
        KPim6::MimeTreeParserCore
        KF6::XmlGui
        KF6::Codecs
        KF6::XmlGui
        KF6::Crash
        KF6::IconThemes
        KF6::Notifications
        MerkuroComponents
)

ecm_add_qml_module(merkuro_mail_static
    URI "org.kde.merkuro.mail"
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES
        QtQuick
        org.kde.kirigamiaddons.formcard
        org.kde.kirigamiaddons.delegates
        org.kde.kirigamiaddons.statefulapp
        org.kde.akonadi
)

ecm_target_qml_sources(merkuro_mail_static SOURCES
    qml/app/Main.qml
    qml/app/MenuBar.qml
    qml/app/GlobalMenuBar.qml
    qml/desktopactions/OpenMbox.qml

    qml/MailSidebar.qml
    qml/FolderView.qml
    qml/MailComposer.qml
    qml/ConversationViewer.qml
    qml/ProgressStatusBar.qml
)
ecm_target_qml_sources(merkuro_mail_static
    PRIVATE PATH private SOURCES
    qml/private/MailDelegate.qml
)

ecm_target_qml_sources(merkuro_mail_static
    PRIVATE PATH actions SOURCES
    qml/actions/NewFolderAction.qml
    qml/actions/DeleteFolderAction.qml
    qml/actions/DeleteMailAction.qml
    qml/actions/MailItemMenu.qml
)

ecm_target_qml_sources(merkuro_mail_static
    PRIVATE PATH mailboxselector SOURCES
    qml/mailboxselector/MailBoxList.qml
    qml/mailboxselector/MailBoxListPage.qml
)

ecm_target_qml_sources(merkuro_mail_static
    PRIVATE PATH mailpartview SOURCES
    qml/mailpartview/ICalPart.qml
)

#### Binary

add_executable(merkuro-mail
    main.cpp
)

target_link_libraries(merkuro-mail
    PRIVATE
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::ConfigGui
        mail_settingsplugin
        merkuro_mail_staticplugin
        merkuro_mail_static
)
target_link_libraries(merkuro-mail PRIVATE
        KF6::I18nQml
)
install(TARGETS merkuro-mail ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.mail.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.mail.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES merkuro.mail.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
