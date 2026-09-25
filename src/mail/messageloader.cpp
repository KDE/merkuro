// SPDX-FileCopyrightText: 2023 g10 Code GmbH
// SPDX-FileContributor: Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "messageloader.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>

MessageLoader::MessageLoader(QObject *parent)
    : QObject(parent)
{
}

Akonadi::Item MessageLoader::item() const
{
    return m_item;
}

qint64 MessageLoader::itemId() const
{
    return m_item.id();
}

void MessageLoader::setItemId(qint64 itemId)
{
    setItem(Akonadi::Item(itemId));
}

void MessageLoader::setItem(const Akonadi::Item &item)
{
    if (m_item == item) {
        return;
    }

    m_item = item;
    Q_EMIT itemChanged();
    if (m_message) {
        m_message.reset();
        Q_EMIT messageChanged();
    }

    auto job = new Akonadi::ItemFetchJob(item, this);
    job->fetchScope().fetchFullPayload();
    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        if (job->error()) {
            qWarning() << "Failed to fetch message:" << job->errorText();
            return;
        }
        const auto items = fetchJob->items();
        if (items.isEmpty()) {
            qWarning() << "Empty fetch job result";
            return;
        }
        const auto item = items.at(0);
        if (item.id() != m_item.id()) {
            return;
        }
        if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
            m_item = item;
            Q_EMIT itemChanged();
            m_message = item.payload<std::shared_ptr<KMime::Message>>();
            Q_EMIT messageChanged();
        } else {
            qWarning() << "This is not a mime item.";
        }
    });
}

std::shared_ptr<KMime::Message> MessageLoader::message() const
{
    return m_message;
}

#include "moc_messageloader.cpp"
