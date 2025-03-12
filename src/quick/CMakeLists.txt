# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(akonadi_quick_plugin
    URI "org.kde.akonadi"
    GENERATE_PLUGIN_SOURCE
)

target_sources(akonadi_quick_plugin PRIVATE
    agentinstance.cpp
    agentinstance.h
    collectioncomboboxmodel.cpp
    collectioncomboboxmodel.h
    collectionpickermodel.cpp
    collectionpickermodel.h
    collection.cpp
    collection.h
    mimetypes.cpp
    mimetypes.h
    agentconfiguration.cpp
    agentconfiguration.h
    tagmanager.h
    tagmanager.cpp
    progressmodel.cpp
    progressmodel.h
)

ecm_target_qml_sources(akonadi_quick_plugin SOURCES
    qml/CollectionComboBox.qml
    qml/CollectionChooserPage.qml
    qml/MobileCollectionComboBox.qml
    qml/AgentConfigurationForm.qml
    qml/TagManagerPage.qml
    qml/ProgressStatusBar.qml
)

ecm_qt_declare_logging_category(akonadi_quick_plugin
    HEADER akonadi_quick_debug.h
    IDENTIFIER AKONADI_QUICK_LOG
    CATEGORY_NAME org.kde.akonadi.quick
    DESCRIPTION "Akonadi QtQuick Plugin"
    EXPORT MERKURO
)

target_link_libraries(akonadi_quick_plugin PRIVATE
    KF6::Contacts
    KF6::WindowSystem
    KPim6::AkonadiWidgets
    KPim6::Libkdepim
    MerkuroComponents
)

ecm_qt_install_logging_categories(
    EXPORT MERKURO
    FILE akonadi.quick.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

ecm_finalize_qml_module(akonadi_quick_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF
)
