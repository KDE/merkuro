# SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
# SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(calutilstest.cpp
    TEST_NAME calutilstest
    LINK_LIBRARIES merkuro_calendar_static Qt::Test
    NAME_PREFIX "merkuro-calendar-"
)

ecm_add_test(remindersmodeltest.cpp
    TEST_NAME remindersmodeltest
    LINK_LIBRARIES merkuro_calendar_static Qt::Test
    NAME_PREFIX "merkuro-calendar-"
)

ecm_add_test(filtertest.cpp
    TEST_NAME filtertest
    LINK_LIBRARIES merkuro_calendar_static Qt::Test
    NAME_PREFIX "merkuro-calendar-"
)

ecm_add_test(timezonelistmodeltest.cpp
    TEST_NAME timezonelistmodeltest
    LINK_LIBRARIES merkuro_calendar_static Qt::Qml Qt::Quick Qt::QuickControls2 Qt::Test
    NAME_PREFIX "merkuro-calendar-"
)

set_tests_properties(merkuro-calendar-timezonelistmodeltest PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

ecm_add_test(infinitemerkurocalendarviewmodeltest.cpp
    TEST_NAME infinitemerkurocalendarviewmodeltest
    LINK_LIBRARIES merkuro_calendar_static Qt::Test
    NAME_PREFIX "merkuro-calendar-"
)

# the tests need the ical resource, which we might not have at this point (e.g. on the CI)
find_program(AKONADI_ICAL_RESOURCE NAMES akonadi_ical_resource)
if(UNIX)
    add_akonadi_isolated_test(SOURCE incidenceoccurrencemodeltest.cpp LINK_LIBRARIES merkuro_calendar_static Qt::Test)
    add_akonadi_isolated_test(SOURCE todosortfilterproxymodeltest.cpp LINK_LIBRARIES merkuro_calendar_static Qt::Test)
endif()

add_executable(calendarqmltestrunner qmltestrunner.cpp)
target_link_libraries(calendarqmltestrunner PRIVATE
    Qt::QuickTest
    merkuro_calendar_static
    merkuro_calendar_staticplugin
)
target_compile_definitions(calendarqmltestrunner PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
)

if(UNIX)
    add_akonadi_isolated_test(
        COMMAND $<TARGET_FILE:calendarqmltestrunner>
        TEST_NAME qmltest
        NAME_PREFIX "merkuro-calendar-"
    )
    foreach(backend sqlite mysql pgsql)
        set(test_name "merkuro-calendar-akonadi-${backend}-qmltest")
        if(TEST ${test_name})
            set_property(TEST ${test_name} APPEND PROPERTY ENVIRONMENT
                "QML2_IMPORT_PATH=$<TARGET_FILE_DIR:MerkuroComponents>:${CMAKE_INSTALL_FULL_LIBDIR}/qml"
                "QT_QPA_PLATFORM=offscreen"
                "QT_QUICK_BACKEND=software"
            )
            set_tests_properties(${test_name} PROPERTIES
                LABELS "qml;akonadi"
                TIMEOUT 120
                TIMEOUT_SIGNAL_NAME "SIGQUIT"
            )
        endif()
    endforeach()
endif()
