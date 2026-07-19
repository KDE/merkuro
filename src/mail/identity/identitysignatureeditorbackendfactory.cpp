// SPDX-FileCopyrightText: 2026 Florian Richer <florian.richer@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "identitysignatureeditorbackendfactory.h"

KIdentityManagementQuick::SignatureEditorBackend *IdentitySignatureEditorBackendFactory::signatureEditorBackend() const
{
    return new KIdentityManagementQuick::SignatureEditorBackend(nullptr);
}

#include "moc_identitysignatureeditorbackendfactory.cpp"
