# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(quick)
add_subdirectory(contacts)
add_subdirectory(mail)
add_subdirectory(calendar)
add_subdirectory(components)
if (MERKURO_FLATPAK)
    add_subdirectory(launcher)
    set(DESKTOP_EXEC "merkurolauncher")
    set(NO_DISPLAY "false")
else()
    set(DESKTOP_EXEC "merkuro-calendar")
    set(NO_DISPLAY "true")
endif()

configure_file(org.kde.merkuro.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/org.kde.merkuro.desktop)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/org.kde.merkuro.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES org.kde.merkuro.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
