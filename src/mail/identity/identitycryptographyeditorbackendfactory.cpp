// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitycryptographyeditorbackendfactory.h"

#include "identitycryptographybackend.h"

KIdentityManagement::Quick::CryptographyEditorBackend *IdentityCryptographyEditorBackendFactory::newCryptoEditorBackend()
{
    const auto cryptoBackend = QSharedPointer<IdentityCryptographyBackend>::create();
    return new KIdentityManagement::Quick::CryptographyEditorBackend(nullptr, std::move(cryptoBackend));
}
