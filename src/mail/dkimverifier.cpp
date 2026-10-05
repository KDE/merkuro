// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "dkimverifier.h"

DkimVerifier::DkimVerifier(QObject *parent)
    : QObject(parent)
{
}

std::shared_ptr<KMime::Message> DkimVerifier::message() const
{
    return m_message;
}

void DkimVerifier::setMessage(const std::shared_ptr<KMime::Message> &message)
{
    if (m_message == message) {
        return;
    }

    // Cancel the previous message's jobs before starting another verification.
    delete m_manager;
    m_manager = nullptr;
    m_message = message;
    m_result = {};
    Q_EMIT messageChanged();
    Q_EMIT resultChanged();

    if (!m_message) {
        return;
    }

    m_manager = new MessageCore::DKIMManager(this);
    connect(m_manager, &MessageCore::DKIMManager::result, this, [this](const auto &result, Akonadi::Item::Id) {
        m_result = result;
        Q_EMIT resultChanged();
    });
    m_manager->checkDKim(m_message);
}

DkimVerifier::Status DkimVerifier::status() const
{
    return static_cast<Status>(m_result.status);
}

QString DkimVerifier::signingDomain() const
{
    return m_result.sdid;
}

bool DkimVerifier::hasWarning() const
{
    return m_result.warning != MessageCore::DKIMCheckSignatureJob::DKIMWarning::Any;
}

#include "moc_dkimverifier.cpp"
