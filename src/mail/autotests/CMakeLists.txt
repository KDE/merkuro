# SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(conversationmodeltest.cpp
    TEST_NAME conversationmodeltest
    LINK_LIBRARIES merkuro_mail_static Qt::Test
    NAME_PREFIX "merkuro-mail-"
)
