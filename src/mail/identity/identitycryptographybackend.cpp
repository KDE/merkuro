// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitycryptographybackend.h"

#include "identitypgpkeylistmodel.h"

IdentityCryptographyBackend::IdentityCryptographyBackend(QObject *parent)
    : QObject(parent)
    , KIdentityManagement::Quick::CryptographyBackendInterface()
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

KIdentityManagement::Identity IdentityCryptographyBackend::identity() const
{
    return m_identity;
}

void IdentityCryptographyBackend::setIdentity(const KIdentityManagement::Identity &identity)
{
    if (identity == m_identity) {
        return;
    }

    m_identity = identity;
    m_openPgpKeyListModel->setEmailFilter(identity.primaryEmailAddress());
}
