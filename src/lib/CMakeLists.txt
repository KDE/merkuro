# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause


add_library(merkuro_lib STATIC)
target_sources(merkuro_lib PRIVATE
    abstractmerkuroapplication.cpp
    abstractmerkuroapplication.h
    colorproxymodel.cpp
    colorproxymodel.h
    sortedcollectionproxymodel.cpp
    sortedcollectionproxymodel.h
)
set_property(TARGET merkuro_lib PROPERTY POSITION_INDEPENDENT_CODE ON)

target_include_directories(merkuro_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(merkuro_lib PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Svg
    KF6::I18n
    KF6::CoreAddons
    KF6::CalendarCore
    KPim6::AkonadiCore
    KPim6::AkonadiCalendar
    KPim6::AkonadiContactCore
    KF6::ConfigWidgets
    KF6::Contacts
    KF6::ItemModels
    KPim6::CalendarUtils
    KPim6::AkonadiWidgets
    KF6::XmlGui
    KPim6::CalendarUtils
    KirigamiAddonsStatefulApp
)
