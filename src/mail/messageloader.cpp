// SPDX-FileCopyrightText: 2023 g10 Code GmbH
// SPDX-FileContributor: Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "messageloader.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KLocalizedString>

MessageLoader::MessageLoader(QObject *parent)
    : QObject(parent)
{
}

Akonadi::Item MessageLoader::item() const
{
    return m_item;
}

void MessageLoader::setItem(const Akonadi::Item &item)
{
    if (m_item == item) {
        return;
    }

    m_item = item;
    Q_EMIT itemChanged();
    m_message.reset();
    Q_EMIT messageChanged();

    if (!m_errorString.isEmpty()) {
        m_errorString.clear();
        Q_EMIT errorStringChanged();
    }

    if (!m_loading) {
        m_loading = true;
        Q_EMIT loadingChanged();
    }

    const auto itemId = item.id();
    auto job = new Akonadi::ItemFetchJob(item, this);
    job->fetchScope().fetchFullPayload();
    connect(job, &Akonadi::ItemFetchJob::result, this, [this, itemId](KJob *job) {
        if (m_item.id() != itemId) {
            return;
        }

        if (m_loading) {
            m_loading = false;
            Q_EMIT loadingChanged();
        }

        auto setError = [this](const QString &error) {
            if (m_errorString == error) {
                return;
            }
            m_errorString = error;
            Q_EMIT errorStringChanged();
        };

        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        if (fetchJob->error()) {
            setError(fetchJob->errorString());
            return;
        }

        const auto items = fetchJob->items();
        if (items.isEmpty()) {
            setError(i18n("The message could not be loaded."));
            return;
        }
        const auto item = items.at(0);
        if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
            m_message = item.payload<std::shared_ptr<KMime::Message>>();
            Q_EMIT messageChanged();
        } else {
            setError(i18n("The message has no MIME payload."));
        }
    });
}

std::shared_ptr<KMime::Message> MessageLoader::message() const
{
    return m_message;
}

bool MessageLoader::loading() const
{
    return m_loading;
}

QString MessageLoader::errorString() const
{
    return m_errorString;
}

#include "moc_messageloader.cpp"
