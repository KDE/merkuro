// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "identityeditorbackend.h"

#include "identitywrapper.h"

using namespace KIdentityManagementCore;

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

uint IdentityEditorBackend::identityUoid() const
{
    if (!m_identity) {
        return 0;
    }

    return m_identity->uoid();
}

void IdentityEditorBackend::setIdentityUoid(uint identityUoid)
{
    if (m_identity && m_identity->uoid() == identityUoid) {
        return;
    }

    auto &identity = m_identityManager->modifyIdentityForUoid(identityUoid);
    const auto identityWrapper = new IdentityWrapper(identity, this);
    setIdentity(identityWrapper);
}

void IdentityEditorBackend::saveIdentity()
{
    m_identityManager->commit();
}

void IdentityEditorBackend::addEmailAlias(const QString &alias)
{
    if (!m_identity) {
        return;
    }

    auto aliases = m_identity->emailAliases();
    aliases.append(alias);
    m_identity->setEmailAliases(aliases);
}

void IdentityEditorBackend::modifyEmailAlias(const QString &originalAlias, const QString &modifiedAlias)
{
    if (!m_identity) {
        return;
    }

    auto aliases = m_identity->emailAliases();
    std::replace(aliases.begin(), aliases.end(), originalAlias, modifiedAlias);
    m_identity->setEmailAliases(aliases);
}

void IdentityEditorBackend::removeEmailAlias(const QString &alias)
{
    if (!m_identity) {
        return;
    }

    auto aliases = m_identity->emailAliases();
    aliases.removeAll(alias);
    m_identity->setEmailAliases(aliases);
}
}
}
