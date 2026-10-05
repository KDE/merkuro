# SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(dkimverifiertest.cpp ../dkimverifier.cpp
    TEST_NAME dkimverifiertest
    LINK_LIBRARIES KPim6::MessageCore Qt::Test Qt::Qml
    NAME_PREFIX "merkuro-mail-"
)
