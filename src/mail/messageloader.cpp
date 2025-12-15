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

void MessageLoader::setItem(const Akonadi::Item &item)
{
    if (m_item == item) {
        return;
    }

    m_item = item;

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        const auto items = fetchJob->items();
        if (items.isEmpty()) {
            qWarning() << "Empty fetch job result";
            return;
        }
        const auto item = items.at(0);
        if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
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
