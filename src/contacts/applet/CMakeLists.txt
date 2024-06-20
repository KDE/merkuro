# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

find_package(Plasma)

if(Plasma_FOUND)
    plasma_install_package(package org.kde.merkuro.contact)
endif()
