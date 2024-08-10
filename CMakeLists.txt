# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

cmake_minimum_required(VERSION 3.16)

# KDE Applications version, managed by release script.
set(RELEASE_SERVICE_VERSION_MAJOR "24")
set(RELEASE_SERVICE_VERSION_MINOR "11")
set(RELEASE_SERVICE_VERSION_MICRO "70")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(merkuro VERSION ${RELEASE_SERVICE_VERSION})

set(QT_REQUIRED_VERSION "6.7.0")
set(KF_MIN_VERSION "6.4.0")

set(AKONADI_CONTACT_VERSION "6.2.40")
set(IDENTITYMANAGEMENT_LIB_VERSION "6.2.40")
set(MAILTRANSPORT_LIB_VERSION "6.2.40")
set(CALENDARUTILS_LIB_VERSION "6.2.40")
set(AKONADICALENDAR_LIB_VERSION "6.2.40")
set(KMIME_LIB_VERSION "6.2.40")
set(AKONADI_LIB_VERSION "6.2.40")
set(MIMETREEPARSER_LIB_VERSION "6.2.40")
set(MAILCOMMON_LIB_VERSION "6.2.40")
set(AKONADIMIME_LIB_VERSION "6.2.40")
set(AKONADICONTACT_LIB_VERSION "6.2.40")
set(KMIME_LIB_VERSION "6.2.40")
set(MESSAGECOMPOSER_LIB_VERSION "6.2.40")
set(KMBOX_LIB_VERSION "6.2.40")
set(LIBKDEPIM_LIB_VERSION "6.2.40")
set(PIMCOMMON_LIB_VERSION "6.2.40")

include(FeatureSummary)

################# set KDE specific information #################
find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    ${ECM_MODULE_PATH}
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEGitCommitHooks)
include(KDEClangFormat)

include(ECMAddTests)
include(ECMCoverageOption)
include(ECMQtDeclareLoggingCategory)
include(ECMSetupVersion)
include(ECMGenerateHeaders)
include(ECMGenerateExportHeader)
include(ECMPoQmTools)
include(ECMDeprecationSettings)
include(ECMFeatureSummary)
include(ECMGenerateQmlTypes)
include(ECMQmlModule)
include(ECMInstallIcons)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h *.c)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX MERKURO
    SOVERSION ${PROJECT_VERSION_MAJOR}
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/config-merkuro.h"
)

################# Find dependencies #################
find_package(Qt6 ${QT_REQUIRED_VERSION} REQUIRED COMPONENTS
    Core
    DBus
    Gui
    Svg
    Test
    Qml
    QuickControls2
    QuickTest
)

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    CalendarCore
    ConfigWidgets
    Contacts
    CoreAddons
    DBusAddons
    I18n
    IconThemes
    ItemModels
    Kirigami
    KIO
    QQC2DesktopStyle
    WindowSystem
    XmlGui
    Notifications
    Crash
)
find_package(KF6KirigamiAddons 1.4.0 REQUIRED)
find_package(Gpgme REQUIRED)
set_package_properties(KF6QQC2DesktopStyle PROPERTIES
    TYPE RUNTIME
)

find_package(KPim6MessageComposer ${MESSAGECOMPOSER_LIB_VERSION} REQUIRED)
find_package(KPim6Akonadi ${AKONADI_LIB_VERSION} REQUIRED)
find_package(KPim6AkonadiCalendar ${AKONADICALENDAR_LIB_VERSION} REQUIRED)
find_package(KPim6AkonadiContactCore ${AKONADI_CONTACT_VERSION} REQUIRED)
find_package(KPim6AkonadiMime ${AKONADIMIME_LIB_VERSION} REQUIRED)
find_package(KPim6CalendarUtils ${CALENDARUTILS_LIB_VERSION} REQUIRED)
find_package(KPim6IdentityManagementCore ${IDENTITYMANAGEMENT_LIB_VERSION} REQUIRED)
find_package(KPim6IdentityManagementQuick ${IDENTITYMANAGEMENT_LIB_VERSION} REQUIRED)
find_package(KPim6MailCommon ${MAILCOMMON_LIB_VERSION} REQUIRED)
find_package(KPim6MailTransport ${MAILTRANSPORT_LIB_VERSION} REQUIRED)
find_package(KPim6MimeTreeParserCore ${MIMETREEPARSER_LIB_VERSION} REQUIRED)
find_package(KPim6Mbox ${KMBOX_LIB_VERSION} REQUIRED)
find_package(KPim6Mime ${KMIME_LIB_VERSION} REQUIRED)
find_package(KPim6Libkdepim ${LIBKDEPIM_LIB_VERSION} CONFIG REQUIRED)
find_package(KPim6PimCommonAkonadi ${PIMCOMMON_LIB_VERSION} CONFIG REQUIRED)

qt_policy(SET QTP0001 NEW)

option(USE_UNITY_CMAKE_SUPPORT "Use UNITY cmake support (speedup compile time)" OFF)

set(COMPILE_WITH_UNITY_CMAKE_SUPPORT OFF)
if(USE_UNITY_CMAKE_SUPPORT)
    set(COMPILE_WITH_UNITY_CMAKE_SUPPORT ON)
    add_definitions(-DUNITY_CMAKE_SUPPORT)
endif()

################# build and install #################

ki18n_install(po)

add_definitions(-DQT_NO_CONTEXTLESS_CONNECT)
ecm_set_disabled_deprecation_versions(QT 6.7.2 KF 6.4.0)
add_definitions(-DQT_STRICT_ITERATORS)
add_subdirectory(src)
add_subdirectory(icons)

ecm_qt_install_logging_categories(
    EXPORT MERKURO
    FILE merkuro.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

ecm_feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
