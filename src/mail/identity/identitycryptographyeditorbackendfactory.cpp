// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "identitycryptographyeditorbackendfactory.h"

#include "identitycryptographybackend.h"

KIdentityManagementCore::Quick::CryptographyEditorBackend *IdentityCryptographyEditorBackendFactory::newCryptoEditorBackend()
{
    const auto cryptoBackend = QSharedPointer<IdentityCryptographyBackend>::create();
    return new KIdentityManagementCore::Quick::CryptographyEditorBackend(nullptr, std::move(cryptoBackend));
}
