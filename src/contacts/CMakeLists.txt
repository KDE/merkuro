# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

### Static lib

add_library(merkuro_contact_static STATIC)

target_link_libraries(merkuro_contact_static PUBLIC
    KF6::XmlGui
    KF6::Contacts
    KPim6::AkonadiWidgets
    KPim6::AkonadiContactCore
    MerkuroComponents
)
set_target_properties(merkuro_contact_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_sources(merkuro_contact_static PUBLIC
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

kconfig_add_kcfg_files(merkuro_contact_static GENERATE_MOC contactconfig.kcfgc)

ecm_qt_declare_logging_category(merkuro_contact_static
    HEADER merkuro_contact_debug.h
    IDENTIFIER MERKURO_LOG
    CATEGORY_NAME org.kde.merkuro.contact
    DESCRIPTION "merkuro contact"
    EXPORT MERKURO
)

ecm_add_qml_module(merkuro_contact_plugin URI "org.kde.merkuro.contact" VERSION 1.0)

target_sources(merkuro_contact_plugin PRIVATE
    contactplugin.cpp
    contactplugin.h
    resources.qrc
)

ecm_target_qml_sources(merkuro_contact_plugin SOURCES
    qml/ContactChooserPage.qml
    qml/AddressBookCollectionHandler.qml
    qml/ContactView.qml
    qml/MenuBar.qml
    qml/Sidebar.qml
    qml/GlobalMenuBar.qml
)

ecm_target_qml_sources(merkuro_contact_plugin
    PRIVATE PATH private SOURCES
    qml/private/ContactPage.qml
    qml/private/ContactGroupPage.qml
    qml/private/ContactsPage.qml
    qml/private/ContactListItem.qml
    qml/private/Header.qml
    qml/private/PhoneNumberDialog.qml
    qml/private/QrCodePage.qml
    qml/private/AddressBookMenu.qml
    qml/private/DeleteContactAction.qml
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


target_link_libraries(merkuro_contact_plugin PRIVATE merkuro_contact_static)

ecm_qt_install_logging_categories(
    EXPORT merkuro
    FILE merkuro.contact.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

if(BUILD_TESTING)
    add_subdirectory(autotests)
endif()

add_subdirectory(applet)

ecm_finalize_qml_module(merkuro_contact_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)

#### Binary

add_executable(merkuro-contact main.cpp resources.qrc)
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
)
install(TARGETS merkuro-contact ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.contact.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.contact.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
