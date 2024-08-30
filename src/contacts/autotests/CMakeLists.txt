# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(emailmodeltest.cpp
    TEST_NAME emailmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(imppmodeltest.cpp
    TEST_NAME imppmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(addressmodeltest.cpp
    TEST_NAME addressmodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)

ecm_add_test(phonemodeltest.cpp
    TEST_NAME phonemodeltest
    LINK_LIBRARIES merkuro_contact Qt::Test
    NAME_PREFIX "merkuro-contact-"
)
