# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

### Contact static lib

add_library(merkuro_contact_static STATIC)
set_target_properties(merkuro_contact_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
kconfig_add_kcfg_files(merkuro_contact_static GENERATE_MOC contactconfig.kcfgc)
ecm_qt_declare_logging_category(merkuro_contact_static
    HEADER merkuro_contact_debug.h
    IDENTIFIER MERKURO_LOG
    CATEGORY_NAME org.kde.merkuro.contact
    DESCRIPTION "merkuro contact"
    EXPORT MERKURO
)

target_link_libraries(merkuro_contact_static PUBLIC KF6::ConfigGui Qt::Qml)

### Contact QML Plugin lib

add_library(merkuro_contact SHARED)

target_link_libraries(merkuro_contact PUBLIC
    KF6::XmlGui
    KF6::Contacts
    KPim6::AkonadiWidgets
    KPim6::AkonadiContactCore
    MerkuroComponents
    merkuro_contact_static
    Gpgmepp
    QGpgmeQt6
    KPim6::Libkleo
)

set_target_properties(merkuro_contact PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_sources(merkuro_contact PUBLIC
    contactapplication.cpp
    contactapplication.h
    addresseewrapper.cpp
    addresseewrapper.h
    addressmodel.cpp
    addressmodel.h
    phonemodel.h
    phonemodel.cpp
    imppmodel.h
    imppmodel.cpp
    emailmodel.h
    emailmodel.cpp
    globalcontactmodel.cpp
    globalcontactmodel.h
    certificatesmodel.cpp
    certificatesmodel.h
    contactactions.cpp
    contactactions.h
    contactmanager.h
    contactmanager.cpp
    contactcollectionmodel.cpp
    contactcollectionmodel.h
    contacteditorbackend.h
    contacteditorbackend.cpp
    contactgroupeditor.h
    contactgroupeditor.cpp
    contactgroupwrapper.h
    contactgroupwrapper.cpp
    contactgroupmodel.h
    contactgroupmodel.cpp
    contactmetadata.cpp
    contactmetadata.h
    contactsmodel.cpp
    contactsmodel.h
    attributes/contactmetadataattribute_p.h
    attributes/contactmetadataattribute.cpp
    attributes/attributeregistrar.cpp
)

ecm_add_qml_module(merkuro_contact_plugin
    URI "org.kde.merkuro.contact"
    GENERATE_PLUGIN_SOURCE
    RESOURCES
        resources/fallbackBackground.png
)

ecm_target_qml_sources(merkuro_contact_plugin SOURCES
    qml/ContactChooserPage.qml
    qml/AddressBookCollectionHandler.qml
    qml/ContactView.qml
    qml/MenuBar.qml
    qml/Sidebar.qml
    qml/GlobalMenuBar.qml
    qml/ContactListItem.qml
    qml/Main.qml
    qml/Settings.qml
)

ecm_target_qml_sources(merkuro_contact_plugin
    PRIVATE PATH private SOURCES
    qml/private/ContactPage.qml
    qml/private/ContactGroupPage.qml
    qml/private/ContactsPage.qml
    qml/private/Header.qml
    qml/private/PhoneNumberDialog.qml
    qml/private/QrCodePage.qml
    qml/private/AddressBookMenu.qml
    qml/private/DeleteContactDialog.qml
)

ecm_target_qml_sources(merkuro_contact_plugin
    PRIVATE PATH private/contact_editor SOURCES
    qml/private/contact_editor/AddressBookEditorCard.qml
    qml/private/contact_editor/BusinessEditorCard.qml
    qml/private/contact_editor/ContactEditorPage.qml
    qml/private/contact_editor/ContactGroupEditorPage.qml
    qml/private/contact_editor/EmailEditorCard.qml
    qml/private/contact_editor/PersonalInfoEditorCard.qml
    qml/private/contact_editor/PhoneEditorCard.qml
    qml/private/contact_editor/PhotoEditor.qml
    qml/private/contact_editor/InstantMessengerEditorCard.qml
)

target_link_libraries(merkuro_contact_plugin PRIVATE
    merkuro_contact
)

ecm_qt_install_logging_categories(
    EXPORT MERKURO
    FILE merkuro.contact.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

if(BUILD_TESTING)
    add_subdirectory(autotests)
endif()

add_subdirectory(applet)

ecm_finalize_qml_module(merkuro_contact_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR})

set_target_properties(merkuro_contact PROPERTIES
    VERSION     ${PROJECT_VERSION}
    SOVERSION   6
    EXPORT_NAME "merkuro_contact_plugin"
)

install(TARGETS merkuro_contact EXPORT MerkuroComponents ${KF_INSTALL_TARGETS_DEFAULT_ARGS})

#### Binary

add_executable(merkuro-contact main.cpp)
target_link_libraries(merkuro-contact
    PRIVATE
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF6::I18n
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::ConfigGui
        KF6::Crash
	KF6::IconThemes
	KF6::ConfigWidgets
        KPim6::Libkleo
)
target_link_libraries(merkuro-contact PUBLIC
   KF6::I18nQml
)

install(TARGETS merkuro-contact ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.contact.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.contact.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
