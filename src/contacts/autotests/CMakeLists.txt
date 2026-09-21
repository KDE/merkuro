# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(emailmodeltest.cpp
    TEST_NAME emailmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(imppmodeltest.cpp
    TEST_NAME imppmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(addressmodeltest.cpp
    TEST_NAME addressmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(phonemodeltest.cpp
    TEST_NAME phonemodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(contactgroupmodeltest.cpp
    TEST_NAME contactgroupmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

if(UNIX)
    add_akonadi_isolated_test(SOURCE addressee_wrapper_test.cpp
        LINK_LIBRARIES merkuro_contact Qt::Test
        NAME_PREFIX "merkuro-contact-"
    )

    add_akonadi_isolated_test(SOURCE editorandrepositorytest.cpp
        LINK_LIBRARIES merkuro_contact Qt::Test
        NAME_PREFIX "merkuro-contact-"
    )
endif()

find_package(Qt6QmlTools ${QT_REQUIRED_VERSION} CONFIG REQUIRED)

add_executable(contactqmltestrunner qmltestrunner.cpp)
target_link_libraries(contactqmltestrunner PRIVATE Qt6::QuickTest merkuro_contact)
target_compile_definitions(contactqmltestrunner PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
)

if(UNIX)
    add_akonadi_isolated_test(
        COMMAND $<TARGET_FILE:contactqmltestrunner>
            TEST_NAME qmltest
            NAME_PREFIX "merkuro-contact-"
        )
    set_property(TEST merkuro-contact-akonadi-sqlite-qmltest APPEND PROPERTY
        ENVIRONMENT "QML2_IMPORT_PATH=$<TARGET_FILE_DIR:merkuro_contact>:${CMAKE_INSTALL_FULL_LIBDIR}/qml"
    )
    set_property(TEST merkuro-contact-akonadi-sqlite-qmltest PROPERTY
        TIMEOUT_SIGNAL_NAME "SIGQUIT"
    )
    if(TEST merkuro-contact-akonadi-mysql-qmltest)
        set_property(TEST merkuro-contact-akonadi-mysql-qmltest APPEND PROPERTY
            ENVIRONMENT "QML2_IMPORT_PATH=$<TARGET_FILE_DIR:merkuro_contact>:${CMAKE_INSTALL_FULL_LIBDIR}/qml"
        )
        set_property(TEST merkuro-contact-akonadi-mysql-qmltest PROPERTY
            TIMEOUT_SIGNAL_NAME "SIGQUIT"
        )
    endif()
endif()
