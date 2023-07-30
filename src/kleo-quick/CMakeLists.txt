# SPDX-FileCopyrightText: (C) 2023 Claudio Cambra <claudio.cambra@kde.org>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(kleo_quick_plugin URI "org.kde.kleo" VERSION 1.0)

target_sources(kleo_quick_plugin PRIVATE
    kleoquickplugin.h
    kleoquickplugin.cpp
)

ecm_target_qml_sources(kleo_quick_plugin SOURCES
    qml/MobileFormKeyComboBoxDelegate.qml
)

ecm_qt_declare_logging_category(kleo_quick_plugin
    HEADER kleo_quick_debug.h
    IDENTIFIER KLEO_QUICK_LOG
    CATEGORY_NAME org.kde.kleo.quick
    DESCRIPTION "Kleo QtQuick Plugin"
    EXPORT MERKURO
)

target_link_libraries(kleo_quick_plugin PRIVATE merkuro_lib
    KF${QT_MAJOR_VERSION}::WindowSystem
    KPim${QT_MAJOR_VERSION}::Libkleo
)

ecm_qt_install_logging_categories(
    EXPORT MERKURO
    FILE kleo.quick.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

ecm_finalize_qml_module(kleo_quick_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF
)
