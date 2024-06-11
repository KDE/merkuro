# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(settings)

set(merkuro_mail_SRCS
    mailapplication.cpp
    mailapplication.h
    mailmanager.cpp
    mailmanager.h
    mailmodel.cpp
    mailmodel.h
    helper.h
    helper.cpp
    contactimageprovider.cpp
    contactimageprovider.h

    messagestatus.h
    messagestatus.cpp
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
)

ecm_qt_declare_logging_category(merkuro_mail_SRCS
    HEADER merkuro_mail_debug.h
    IDENTIFIER "merkuro_MAIL_LOG"
    CATEGORY_NAME org.kde.merkuro.mail
    DESCRIPTION "merkuro mail"
    EXPORT merkuro
)

add_library(merkuro_mail_static STATIC ${merkuro_mail_SRCS})
set_target_properties(merkuro_mail_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(merkuro_mail_static
    PUBLIC
        merkuro_lib
        KPim6::MessageComposer 
        KPim6::MailCommon
        KPim6::MailTransport
        KPim6::AkonadiMime
        KPim6::IdentityManagementQuick
        KPim6::Mbox
        KPim6::Mime
        KPim6::Libkdepim
        KPim6::PimCommonAkonadi
        KF6::XmlGui
        KF6::Codecs
        KF6::XmlGui
        KF6::Notifications
)

ecm_add_qml_module(merkuro_mail_plugin URI "org.kde.merkuro.mail" VERSION 1.0)

target_sources(merkuro_mail_plugin PRIVATE
    mailplugin.cpp
    mailplugin.h
)

ecm_target_qml_sources(merkuro_mail_plugin SOURCES
    qml/MailSidebar.qml
    qml/FolderView.qml
    qml/MailComposer.qml
    qml/ConversationViewer.qml
)
ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH private SOURCES
    qml/private/AttachmentDelegate.qml
    qml/private/MailDelegate.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH actions SOURCES
    qml/actions/NewFolderAction.qml
    qml/actions/DeleteFolderAction.qml
    qml/actions/MailItemMenu.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH desktopactions SOURCES
    qml/desktopactions/openmbox.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH mailboxselector SOURCES
    qml/mailboxselector/MailBoxList.qml
    qml/mailboxselector/MailBoxListPage.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH mailpartview SOURCES
    qml/mailpartview/ICalPart.qml
)

target_link_libraries(merkuro_mail_plugin
    PUBLIC
        merkuro_mail_static
        KPim6::MimeTreeParserCore
)

ecm_finalize_qml_module(merkuro_mail_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)

#### Binary

add_executable(merkuro-mail 
    main.cpp 
    resources.qrc 
    messagehandler.cpp 
    messagehandler.h
)

target_link_libraries(merkuro-mail
    PRIVATE
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF6::I18n
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::ConfigGui
        KPim6::Mime
        KPim6::MimeTreeParserCore
        mail_settingsplugin
)
install(TARGETS merkuro-mail ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.mail.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.mail.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES merkuro-mail.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
