// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "identityeditorbackend.h"

#include "identitywrapper.h"

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{

IdentityEditorBackend::Mode IdentityEditorBackend::mode() const
{
    return m_mode;
}

void IdentityEditorBackend::setMode(Mode mode)
{
    if (m_mode == mode) {
        return;
    }

    m_mode = mode;
    Q_EMIT modeChanged();
}

IdentityWrapper *IdentityEditorBackend::identity() const
{
    return m_identity;
}

void IdentityEditorBackend::setIdentity(IdentityWrapper *identity)
{
    if (m_identity == identity) {
        return;
    }

    m_identity = identity;
    Q_EMIT identityChanged();
}

uint IdentityEditorBackend::identityUiod() const
{
    if (!m_identity) {
        return 0;
    }

    return m_identity->uoid();
}

void IdentityEditorBackend::setIdentityUiod(uint identityUiod)
{
    if (m_identity && m_identity->uoid() == identityUiod) {
        return;
    }

    const auto identity = m_identityManager->modifyIdentityForUoid(identityUiod);
    setIdentity(new IdentityWrapper(identity, this));
}

void IdentityEditorBackend::saveIdentity()
{
    if (!m_identity) {
        return;
    }

    m_identityManager->commit();
}
}
}