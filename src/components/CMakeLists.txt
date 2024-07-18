# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

# target: shared C++ library

set(merkuro_components_SRCS)

ecm_qt_declare_logging_category(merkuro_components_SRCS
    HEADER merkuro_components_debug.h
    IDENTIFIER "merkuro_components_LOG"
    CATEGORY_NAME org.kde.merkuro.components
    DESCRIPTION "merkuro components"
    EXPORT merkuro
)

add_library(MerkuroComponents SHARED
    abstractmerkuroapplication.cpp
    abstractmerkuroapplication.h
    colorproxymodel.cpp
    colorproxymodel.h
    sortedcollectionproxymodel.cpp
    sortedcollectionproxymodel.h
    ${merkuro_components_SRCS}
)

ecm_setup_version(PROJECT
    VARIABLE_PREFIX MERKUROCOMPONENTS
    PACKAGE_VERSION_FILE "${CMAKE_CURRENT_BINARY_DIR}/MerkuroComponentsConfigVersion.cmake"
    SOVERSION 6
)

ecm_generate_export_header(MerkuroComponents
    VERSION ${PROJECT_VERSION}
    BASE_NAME MerkuroComponents
    DEPRECATION_VERSIONS
)

set_target_properties(MerkuroComponents PROPERTIES
    VERSION     ${PROJECT_VERSION}
    SOVERSION   6
    EXPORT_NAME "MerkuroComponents"
)

target_link_libraries(MerkuroComponents PUBLIC
    KirigamiAddonsStatefulApp
    KF6::I18n
    KF6::CalendarCore
    KF6::Contacts
    KPim6::AkonadiCore
)

target_include_directories(MerkuroComponents
    INTERFACE
        "$<INSTALL_INTERFACE:${KDE_INSTALL_INCLUDEDIR}/MerkuroComponents>"
)

# target: shared QML library

ecm_add_qml_module(MerkuroComponents
    URI "org.kde.merkuro.components"
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
    DEPENDENCIES org.kde.kirigamiaddons.statefulapp
)

ecm_target_qml_sources(MerkuroComponents SOURCES
    QML_FILES
        # Shell components
        qml/BaseApplication.qml

        # In window-menu components
        qml/EditMenu.qml
        qml/FileMenu.qml
        qml/WindowMenu.qml
        qml/HelpMenu.qml
        qml/SettingsMenu.qml

        # global menu components
        qml/NativeFileMenu.qml
        qml/NativeEditMenu.qml
        qml/NativeHelpMenu.qml
        qml/NativeWindowMenu.qml

        # Small controls
        qml/ColoredCheckbox.qml
)

ecm_finalize_qml_module(MerkuroComponents
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF
)

# Install

install(TARGETS MerkuroComponents EXPORT MerkuroComponents ${KF_INSTALL_TARGETS_DEFAULT_ARGS})

