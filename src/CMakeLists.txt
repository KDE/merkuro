# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(quick)
add_subdirectory(contacts)
add_subdirectory(mail)
add_subdirectory(calendar)
add_subdirectory(components)

install(FILES org.kde.merkuro.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
