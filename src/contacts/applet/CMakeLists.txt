# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

find_package(KF6Plasma)

if (KF6Plasma_FOUND)
    plasma_install_package(package org.kde.merkuro.contact)
endif()
