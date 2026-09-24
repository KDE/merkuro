# SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(MerkuroContactImageProvider STATIC
    contactimageprovider.cpp
    contactimageprovider.h
)
set_target_properties(MerkuroContactImageProvider PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(MerkuroContactImageProvider PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(MerkuroContactImageProvider
    PUBLIC
        Qt::Quick
        Qt::Network
        KF6::Contacts
        KPim6::AkonadiContactCore
    PRIVATE
        KF6::I18n
        KF6::KIOCore
)

if(BUILD_TESTING)
    ecm_add_test(contactimageprovidertest.cpp
        TEST_NAME contactimageprovidertest
        LINK_LIBRARIES MerkuroContactImageProvider Qt::Test
        NAME_PREFIX "merkuro-"
    )
    set_tests_properties(merkuro-contactimageprovidertest PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()
