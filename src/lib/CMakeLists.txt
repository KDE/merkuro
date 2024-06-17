# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_library(merkuro_lib STATIC)
target_sources(merkuro_lib PRIVATE
    colorproxymodel.cpp
    colorproxymodel.h
    sortedcollectionproxymodel.cpp
    sortedcollectionproxymodel.h
)
set_property(TARGET merkuro_lib PROPERTY POSITION_INDEPENDENT_CODE ON)

target_include_directories(merkuro_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(merkuro_lib
    PUBLIC
        Qt::Core
        KF6::CoreAddons
        KF6::CalendarCore
        KPim6::AkonadiCore
    PRIVATE
        KPim6::AkonadiCalendar
        KPim6::AkonadiContactCore
        KF6::ConfigWidgets
        KF6::Contacts
        KF6::ItemModels
        KPim6::CalendarUtils
)
