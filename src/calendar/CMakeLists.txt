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
    importer.h
    importer.cpp

    models/attachmentsmodel.cpp
    models/attachmentsmodel.h
    models/attendeesmodel.cpp
    models/attendeesmodel.h
    models/hourlyincidencemodel.cpp
    models/hourlyincidencemodel.h
    models/holidaymodel.h
    models/holidaymodel.cpp
    models/holidayregionmodel.cpp
    models/holidayregionmodel.h
    models/incidenceoccurrencemodel.cpp
    models/incidenceoccurrencemodel.h
    models/infinitemerkurocalendarviewmodel.cpp
    models/infinitemerkurocalendarviewmodel.h
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

    foreigntypes.h
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
    KF6::Crash
    KF6::Holidays
    KPim6::AkonadiCalendar
    KPim6::AkonadiContactCore
    KPim6::AkonadiWidgets
    KPim6::CalendarUtils
    MerkuroComponents
    PRIVATE KF6::I18nQml
)

set_source_files_properties(qml/Controls/DatePopupSingleton.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

set_source_files_properties(qml/CalendarUtils/CalendarUiUtils.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

set_source_files_properties(qml/IncidenceEditorManager.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

ecm_add_qml_module(merkuro_calendar_static GENERATE_PLUGIN_SOURCE
    URI "org.kde.merkuro.calendar"
    DEPENDENCIES
        QtLocation
        org.kde.merkuro.components
        org.kde.akonadi
        QtCore
        QtGui
    QML_FILES
        qml/incidenceeditor/ReminderDelegate.qml
        qml/incidenceeditor/PriorityComboBox.qml
        qml/BottomToolBar.qml
        qml/Menus/MenuBar.qml
        qml/Controls/DatePopupSingleton.qml
        qml/Main.qml

        qml/Menus/GlobalMenuBar.qml
        qml/Drawers/MainDrawer.qml
        qml/Drawers/IncidenceInfoDrawer.qml

        qml/Bars/FilterHeaderBar.qml
        qml/Bars/DayLabelsBar.qml

        qml/Delegates/IncidenceDelegateBackground.qml
        qml/Delegates/DayGridViewIncidenceDelegate.qml
        qml/Delegates/ViewTitleDelegate.qml
        qml/Delegates/RelatedIncidenceDelegate.qml

        qml/MainViews/DayGridViewBackground.qml
        qml/MainViews/DayGridViewForeground.qml
        qml/MainViews/DayGridView.qml
        qml/MainViews/SwipeableMonthGridView.qml
        qml/MainViews/MonthView.qml
        qml/MainViews/SwipeableMonthListView.qml
        qml/MainViews/BasicMonthListView.qml
        qml/MainViews/ScheduleView.qml
        qml/MainViews/TodoTreeView.qml
        qml/MainViews/TodoView.qml
        qml/MainViews/SwipeableInternalHourlyView.qml
        qml/MainViews/BasicInternalHourlyView.qml
        qml/MainViews/WeekViewHolidayRow.qml
        qml/MainViews/HourlyView.qml

        qml/CalendarUtils/DateUtils.js
        qml/CalendarUtils/LabelUtils.js
        qml/CalendarUtils/CalendarUiUtils.qml

        qml/IncidenceEditorManager.qml
        qml/Dialogs/IncidenceEditorPage.qml
        qml/Dialogs/IncidenceEditorDialog.qml
        qml/Dialogs/DeleteIncidenceDialog.qml
        qml/Dialogs/DeleteCalendarDialog.qml
        qml/Dialogs/CollectionPickerPage.qml
        qml/Dialogs/RecurringIncidenceChangePage.qml
        qml/Dialogs/EditCalendarPage.qml

        qml/Controls/DateControls/TimePicker.qml
        qml/Controls/DateControls/TimeCombo.qml
        qml/Controls/DateControls/DateCombo.qml

        qml/Controls/TitleDateButton.qml
        qml/Controls/IncidenceMouseArea.qml
        qml/Controls/KBMNavigationMouseArea.qml
        qml/Controls/DayTapHandler.qml
        qml/Controls/Tag.qml
        qml/Controls/ResizerSeparator.qml
        qml/Controls/CalendarItemTapHandler.qml
        qml/Controls/TodoCheckBox.qml
        qml/Controls/IncidenceInfoContents.qml
        qml/Controls/IncidenceInfoPopup.qml
        qml/Controls/CheckableCollectionNavigationView.qml
        qml/Controls/MainDrawerToggleButton.qml
        qml/Controls/ImportHandler.qml

        qml/Location/LocationMap.qml

        qml/Settings/ConfigurationsView.qml
        qml/Settings/FreeBusySettingsPage.qml
        qml/Settings/ViewSettingsPage.qml
        qml/Settings/SourceSettingsPage.qml

        qml/Menus/CalendarItemMenu.qml
)

target_include_directories(merkuro_calendar_static PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models)

set_source_files_properties(models/todosortfilterproxymodel.cpp PROPERTIES SKIP_UNITY_BUILD_INCLUSION ON)

if(BUILD_TESTING)
    add_subdirectory(autotests)
endif()

#### Binary

add_executable(merkuro-calendar
    main.cpp
)
target_link_libraries(merkuro-calendar
    PRIVATE
        merkuro_calendar_staticplugin
        merkuro_calendar_static
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF6::I18n
        KF6::CoreAddons
        KF6::DBusAddons
        KF6::WindowSystem
        KF6::IconThemes
        KF6::ConfigWidgets
        KF6::ConfigGui
)

install(TARGETS merkuro-calendar ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.merkuro.calendar.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.calendar.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
