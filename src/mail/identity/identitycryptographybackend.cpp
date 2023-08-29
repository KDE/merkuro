// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "identitycryptographybackend.h"

#include "identitykeylistmodel.h"

IdentityCryptographyBackend::IdentityCryptographyBackend(QObject *parent)
    : QObject(parent)
    , KIdentityManagementCore::Quick::CryptographyBackendInterface()
    , m_openPgpKeyListModel(new IdentityKeyListModel(this, IdentityKeyListModel::TypeKeys::OpenPGPTypeKeys))
    , m_smimeKeyListModel(new IdentityKeyListModel(this, IdentityKeyListModel::TypeKeys::SMimeTypeKeys))
{
}

QAbstractItemModel *IdentityCryptographyBackend::openPgpKeyListModel() const
{
    return m_openPgpKeyListModel;
}

QAbstractItemModel *IdentityCryptographyBackend::smimeKeyListModel() const
{
    return m_smimeKeyListModel;
}

KIdentityManagementCore::Identity IdentityCryptographyBackend::identity() const
{
    return m_identity;
}

void IdentityCryptographyBackend::setIdentity(const KIdentityManagementCore::Identity &identity)
{
    if (identity == m_identity) {
        return;
    }

    m_identity = identity;
    m_openPgpKeyListModel->setEmailFilter(identity.primaryEmailAddress());
    m_smimeKeyListModel->setEmailFilter(identity.primaryEmailAddress());
}
