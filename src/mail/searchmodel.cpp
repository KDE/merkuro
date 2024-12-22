// SPDX-FileCopyrightText: 2024 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "searchmodel.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/MessageParts>
#include <KMime/Message>
#include <PIM/emailquery.h>
#include <PIM/resultiterator.h>

SearchModel::SearchModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SearchModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.count();
}

QVariant SearchModel::data(const QModelIndex &idx, int role) const
{
    Q_ASSERT(checkIndex(idx, QAbstractItemModel::CheckIndexOption::IndexIsValid));
    const Akonadi::Item &item = m_items[idx.row()];
    return AbstractMailModel::dataFromItem(item, role);
}

QHash<int, QByteArray> SearchModel::roleNames() const
{
    return AbstractMailModel::roleNames();
}

QString SearchModel::searchString() const
{
    return m_searchString;
}

void SearchModel::setSearchString(const QString &searchString)
{
    if (m_searchString == searchString) {
        return;
    }
    m_searchString = searchString;
    Q_EMIT searchStringChanged();

    Akonadi::Search::PIM::EmailQuery query;
    query.bodyMatches(m_searchString);

    Akonadi::Search::PIM::ResultIterator it = query.exec();
    QList<Akonadi::Item::Id> itemIds;
    int i = 0;
    while (it.next() && i <= 40) {
        itemIds << it.id();
        i++;
    }

    m_job = new Akonadi::ItemFetchJob(itemIds, this);
    m_job->fetchScope().fetchPayloadPart(Akonadi::MessagePart::Envelope);
    connect(m_job, &Akonadi::ItemFetchJob::result, this, &SearchModel::slotItemsFetched);
    m_job->start();
}

void SearchModel::slotItemsFetched(KJob *job)
{
    auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
    Q_ASSERT(fetchJob);

    if (fetchJob != m_job) {
        return;
    }

    if (fetchJob->error()) {
        qWarning() << fetchJob->errorString();
        return;
    }

    beginResetModel();
    m_items = fetchJob->items();
    endResetModel();
}

#include "moc_searchmodel.cpp"
