# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(merkuro_components_SRCS)

ecm_qt_declare_logging_category(merkuro_components_SRCS
    HEADER merkuro_components_debug.h
    IDENTIFIER "merkuro_components_LOG"
    CATEGORY_NAME org.kde.merkuro.components
    DESCRIPTION "merkuro components"
    EXPORT merkuro
)

ecm_qt_export_logging_category(
    IDENTIFIER "merkuro_components_LOG"
    CATEGORY_NAME "org.kde.merkuro.components"
    DESCRIPTION "merkuro - components"
    EXPORT merkuro
)

add_library(merkuro_components_static STATIC ${merkuro_components_SRCS})
set_target_properties(merkuro_components_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(merkuro_components_static PUBLIC merkuro_lib)

ecm_add_qml_module(merkuro_components_plugin URI "org.kde.merkuro.components" VERSION 1.0)

target_sources(merkuro_components_plugin PRIVATE
    componentsplugin.cpp
    componentsplugin.h
    helper.cpp
    helper.h
)

ecm_target_qml_sources(merkuro_components_plugin SOURCES
    # Shell components
    qml/BaseApplication.qml
    qml/KQuickCommandBarPage.qml

    # In window-menu components
    qml/KActionFromAction.qml
    qml/ViewMenu.qml
    qml/EditMenu.qml
    qml/FileMenu.qml
    qml/WindowMenu.qml
    qml/HelpMenu.qml
    qml/SettingsMenu.qml

    # global menu components
    qml/NativeMenuItemFromAction.qml
    qml/NativeFileMenu.qml
    qml/NativeEditMenu.qml
    qml/NativeHelpMenu.qml
    qml/NativeWindowMenu.qml

    # Small controls
    qml/ColoredCheckbox.qml
)

target_link_libraries(merkuro_components_plugin PUBLIC merkuro_components_static)

ecm_finalize_qml_module(merkuro_components_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)