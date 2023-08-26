// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitycryptographybackend.h"

#include "identitypgpkeylistmodel.h"

IdentityCryptographyBackend::IdentityCryptographyBackend()
    : KIdentityManagement::Quick::AbstractCryptographyBackend()
{
}

KIdentityManagement::Quick::AbstractKeyListModel *IdentityCryptographyBackend::openPgpKeyListModel() const
{
    return m_openPgpKeyListModel;
}

KIdentityManagement::Quick::AbstractKeyListModel *IdentityCryptographyBackend::smimeKeyListModel() const
{
    return m_smimeKeyListModel;
}
