// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "identitycryptographyeditorbackendfactory.h"

#include "identitycryptographybackend.h"

KIdentityManagementQuick::CryptographyEditorBackend *IdentityCryptographyEditorBackendFactory::newCryptoEditorBackend()
{
    const auto cryptoBackend = QSharedPointer<IdentityCryptographyBackend>::create();
    return new KIdentityManagementQuick::CryptographyEditorBackend(nullptr, std::move(cryptoBackend));
}

#include "moc_identitycryptographyeditorbackendfactory.cpp"
