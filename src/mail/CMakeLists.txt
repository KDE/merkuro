# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

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
    KPim${QT_MAJOR_VERSION}::MailCommon
    KPim${QT_MAJOR_VERSION}::MailTransport
    KPim${QT_MAJOR_VERSION}::AkonadiMime
    KPim${QT_MAJOR_VERSION}::IdentityManagementQuick
    KF${QT_MAJOR_VERSION}::Codecs
    KF${QT_MAJOR_VERSION}::XmlGui
)

if(QT_MAJOR_VERSION STREQUAL "6")
    target_link_libraries(merkuro_mail_static PUBLIC Qt::Core5Compat)
endif()

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
    PRIVATE PATH mailboxselector SOURCES
    qml/mailboxselector/MailBoxList.qml
    qml/mailboxselector/MailBoxListPage.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH mailpartview SOURCES
    qml/mailpartview/ICalPart.qml
)

target_link_libraries(merkuro_mail_plugin PUBLIC merkuro_mail_static)

ecm_finalize_qml_module(merkuro_mail_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)

#### Binary

add_executable(merkuro-mail main.cpp resources.qrc)
target_link_libraries(merkuro-mail
    PRIVATE
    Qt::Widgets
    Qt::Quick
    Qt::QuickControls2
    KF${QT_MAJOR_VERSION}::I18n
    KF${QT_MAJOR_VERSION}::CoreAddons
    KF${QT_MAJOR_VERSION}::DBusAddons
    KF${QT_MAJOR_VERSION}::WindowSystem
    KF${QT_MAJOR_VERSION}::ConfigGui
)
install(TARGETS merkuro-mail ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.mail.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.mail.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
