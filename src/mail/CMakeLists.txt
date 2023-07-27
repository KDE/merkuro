# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

if (BUILD_TESTING)
    add_subdirectory(tests)
    add_subdirectory(mime/tests)
    add_subdirectory(mimetreeparser/autotests)
    add_subdirectory(mimetreeparser/tests)
endif()

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

    crypto.cpp
    mimetreeparser/messagepart.cpp
    mimetreeparser/bodypartformatter.cpp
    mimetreeparser/bodypartformatter_impl.cpp
    mimetreeparser/bodypartformatterbasefactory.cpp
    mimetreeparser/bodypartformatterbasefactory.cpp
    mimetreeparser/cryptohelper.cpp
    mimetreeparser/messagepart.cpp
    mimetreeparser/mimetreeparser_debug.cpp 
    mimetreeparser/mimetreeparser_debug.h
    mimetreeparser/objecttreeparser.cpp
    mimetreeparser/utils.cpp
    mime/attachmentmodel.cpp
    mime/htmlutils.cpp
    mime/mailcrypto.cpp
    mime/mailtemplates.cpp
    mime/messageparser.cpp
    mime/partmodel.cpp

    mailheadermodel.h
    mailheadermodel.cpp

    crypto.h
    mimetreeparser/messagepart.h
    mimetreeparser/bodypartformatter.h
    mimetreeparser/bodypartformatterbasefactory.h
    mimetreeparser/bodypartformatterbasefactory.h
    mimetreeparser/cryptohelper.h
    mimetreeparser/messagepart.h
    mimetreeparser/objecttreeparser.h
    mimetreeparser/utils.h
    mime/attachmentmodel.h
    mime/htmlutils.h
    mime/mailcrypto.h
    mime/mailtemplates.h
    mime/messageparser.h
    mime/partmodel.h

)

ecm_qt_declare_logging_category(merkuro_mail_SRCS
    HEADER merkuro_mail_debug.h
    IDENTIFIER "merkuro_MAIL_LOG"
    CATEGORY_NAME org.kde.merkuro.mail
    DESCRIPTION "merkuro mail"
    EXPORT merkuro
)

ecm_qt_export_logging_category(
    IDENTIFIER "merkuro_MAIL_LOG"
    CATEGORY_NAME "org.kde.merkuro.mail"
    DESCRIPTION "merkuro - mail"
    EXPORT merkuro
)

add_library(merkuro_mail_static STATIC ${merkuro_mail_SRCS})
set_target_properties(merkuro_mail_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(merkuro_mail_static
    PUBLIC
        merkuro_lib
        KPim6::MailCommon
        KPim6::AkonadiMime
        KF6::Codecs
        KF6::XmlGui
)

target_link_libraries(merkuro_mail_static PUBLIC Qt::Core5Compat)

ecm_add_qml_module(merkuro_mail_plugin URI "org.kde.merkuro.mail" VERSION 1.0)

target_sources(merkuro_mail_plugin PRIVATE
    mailplugin.cpp
    mailplugin.h
)

ecm_target_qml_sources(merkuro_mail_plugin SOURCES
    qml/MailSidebar.qml
    qml/FolderView.qml
    qml/MailViewer.qml
    qml/MailComposer.qml
    qml/ConversationViewer.qml
)
ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH private SOURCES
    qml/private/AttachmentDelegate.qml
    qml/private/MailDelegate.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH mailboxselector SOURCES
    qml/mailboxselector/MailBoxList.qml
    qml/mailboxselector/MailBoxListPage.qml
)

ecm_target_qml_sources(merkuro_mail_plugin
    PRIVATE PATH mailpartview SOURCES
    qml/mailpartview/HtmlPart.qml
    qml/mailpartview/ICalPart.qml
    qml/mailpartview/MailPart.qml
    qml/mailpartview/MailPartModel.qml
    qml/mailpartview/MailPartView.qml
    qml/mailpartview/TextPart.qml
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
        KF6::I18n
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::ConfigGui
)
install(TARGETS merkuro-mail ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.mail.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.mail.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
