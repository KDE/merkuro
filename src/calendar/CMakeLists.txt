# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(merkuro_calendar_SRCS
    remindersmodel.h
    remindersmodel.cpp
    utils.h
    utils.cpp

    datetimestate.h
    datetimestate.cpp

    calendarmanager.cpp
    calendarmanager.h
    calendarapplication.cpp
    calendarapplication.h
    filter.cpp
    filter.h
    incidencewrapper.cpp
    incidencewrapper.h
    mousetracker.cpp
    mousetracker.h

    models/attachmentsmodel.cpp
    models/attachmentsmodel.h
    models/attendeesmodel.cpp
    models/attendeesmodel.h
    models/hourlyincidencemodel.cpp
    models/hourlyincidencemodel.h
    models/incidenceoccurrencemodel.cpp
    models/incidenceoccurrencemodel.h
    models/infinitecalendarviewmodel.cpp
    models/infinitecalendarviewmodel.h
    models/itemtagsmodel.cpp
    models/itemtagsmodel.h
    models/monthmodel.cpp
    models/monthmodel.h
    models/multidayincidencemodel.cpp
    models/multidayincidencemodel.h
    models/recurrenceexceptionsmodel.cpp
    models/recurrenceexceptionsmodel.h
    models/timezonelistmodel.cpp
    models/timezonelistmodel.h
    models/todosortfilterproxymodel.cpp
    models/todosortfilterproxymodel.h
)

ecm_qt_declare_logging_category(merkuro_calendar_SRCS
    HEADER merkuro_calendar_debug.h
    IDENTIFIER "MERKURO_CALENDAR_LOG"
    CATEGORY_NAME org.kde.merkuro.calendar
    DESCRIPTION "merkuro calendar"
    EXPORT MERKURO
)

qt_add_dbus_adaptor(merkuro_calendar_SRCS org.kde.calendar.Calendar.xml calendarapplication.h CalendarApplication)

add_library(merkuro_calendar_static STATIC ${merkuro_calendar_SRCS})
kconfig_add_kcfg_files(merkuro_calendar_static GENERATE_MOC calendarconfig.kcfgc)
set_target_properties(merkuro_calendar_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(merkuro_calendar_static PUBLIC
    Qt::DBus
    KF6::WindowSystem
    KF6::Contacts
    KPim6::AkonadiCalendar
    KPim6::AkonadiContactCore
    KPim6::AkonadiWidgets
    KPim6::CalendarUtils
    MerkuroComponents
)


ecm_add_qml_module(merkuro_calendar_plugin URI "org.kde.merkuro.calendar" VERSION 1.0)

target_sources(merkuro_calendar_plugin PRIVATE
    calendarplugin.cpp
    calendarplugin.h
)

set_source_files_properties(models/todosortfilterproxymodel.cpp PROPERTIES SKIP_UNITY_BUILD_INCLUSION ON)

ecm_target_qml_sources(merkuro_calendar_plugin SOURCES
    qml/incidenceeditor/ReminderDelegate.qml
    qml/incidenceeditor/PriorityComboBox.qml
    qml/BottomToolBar.qml
    qml/Menus/MenuBar.qml
    qml/Controls/DatePopupSingleton.qml
)

set_source_files_properties(qml/Controls/DatePopupSingleton.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

target_link_libraries(merkuro_calendar_plugin PUBLIC merkuro_calendar_static)

ecm_finalize_qml_module(merkuro_calendar_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS ON)

if(BUILD_TESTING)
    add_subdirectory(autotests)
endif()

#### Binary

add_executable(merkuro-calendar
    main.cpp
    importer.h
    importer.cpp
    resources.qrc
)
target_link_libraries(merkuro-calendar
    PRIVATE
        merkuro_calendar_static
        merkuro_contact_plugin
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF6::I18n
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::ConfigGui
)
install(TARGETS merkuro-calendar ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.calendar.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.calendar.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
