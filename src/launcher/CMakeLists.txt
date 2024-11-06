# SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_executable(merkurolauncher main.cpp helper.cpp helper.h)

qt_add_qml_module(merkurolauncher
    URI org.kde.merkuro
    QML_FILES
        Main.qml
    DEPENDENCIES
        QtQuick
        org.kde.kirigamiaddons.formcard
)

target_link_libraries(merkurolauncher PUBLIC
    Qt::Quick
    Qt::QuickControls2
    Qt::Widgets
    Qt::Svg
    KF6::I18n
    KF6::CoreAddons
    KF6::Crash
    KF6::KIOWidgets
)

if(TARGET KF6::I18nQml)
target_link_libraries(merkurolauncher PRIVATE
        KF6::I18nQml
)
endif()

install(TARGETS merkurolauncher ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
