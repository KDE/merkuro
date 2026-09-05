// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailpresentationmodel.h"

#include <Akonadi/MessageStatus>
#include <MessageList/MessageModel>
#include <QDateTime>

MailPresentationModel::MailPresentationModel(QObject *parent)
    : QIdentityProxyModel(parent)
    , m_messageModel(std::make_unique<MessageList::MessageModel>(this))
{
    setSourceModel(m_messageModel.get());

    connect(m_messageModel.get(),
            &QAbstractItemModel::dataChanged,
            this,
            [this](const QModelIndex &topLeft, const QModelIndex &bottomRight, const QList<int> &) {
                QList<QModelIndex> roots;
                for (int row = topLeft.row(); row <= bottomRight.row(); ++row) {
                    const auto sourceIndex = m_messageModel->index(row, 0, topLeft.parent());
                    auto ancestorIndex = sourceIndex;
                    while (ancestorIndex.isValid()) {
                        if (!roots.contains(ancestorIndex)) {
                            roots.append(ancestorIndex);
                            const auto proxyIndex = mapFromSource(ancestorIndex);
                            Q_EMIT dataChanged(proxyIndex, proxyIndex, {ThreadSectionDateRole, UnreadDescendantCountRole, ThreadSendersRole});
                        }
                        ancestorIndex = ancestorIndex.parent();
                    }
                }
            });
}

Akonadi::EntityTreeModel *MailPresentationModel::entryTreeModel() const
{
    return m_entityTreeModel;
}

void MailPresentationModel::setEntityTreeModel(Akonadi::EntityTreeModel *entityTreeModel)
{
    if (m_entityTreeModel == entityTreeModel) {
        return;
    }

    m_entityTreeModel = entityTreeModel;
    m_messageModel->setEntityTreeModel(entityTreeModel);
    Q_EMIT entityTreeModelChanged();
}

QItemSelectionModel *MailPresentationModel::collectionSelectionModel() const
{
    return m_collectionSelectionModel;
}

void MailPresentationModel::setCollectionSelectionModel(QItemSelectionModel *collectionSelectionModel)
{
    if (m_collectionSelectionModel == collectionSelectionModel) {
        return;
    }

    m_collectionSelectionModel = collectionSelectionModel;
    m_messageModel->setCollectionSelectionModel(collectionSelectionModel);
    Q_EMIT collectionSelectionModelChanged();
}

Akonadi::Item::List MailPresentationModel::conversationItems(const Akonadi::Item &seedItem) const
{
    Akonadi::Item::List items;
    const auto seedIndex = m_messageModel->indexForItemId(seedItem.id());
    if (!seedIndex.isValid()) {
        return items;
    }

    const auto rootIndex = m_messageModel->threadRoot(seedIndex);
    const auto itemIds = m_messageModel->threadItemIds(rootIndex);
    items.reserve(itemIds.size());

    for (const auto itemId : itemIds) {
        const auto itemIndex = m_messageModel->indexForItemId(itemId);
        if (!itemIndex.isValid()) {
            continue;
        }

        const auto item = itemIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.isValid()) {
            items.append(item);
        }
    }

    return items;
}

MessageList::Core::Aggregation::Threading MailPresentationModel::threading() const
{
    return m_messageModel->threading();
}

QVariant MailPresentationModel::threadSectionDate(const QModelIndex &sourceIndex) const
{
    const auto rootIndex = m_messageModel->threadRoot(sourceIndex);

    Akonadi::Item latestItem;
    QDateTime latestDate;
    const auto visit = [&](const auto &visit, const QModelIndex &itemIndex) -> void {
        const auto item = itemIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto date = AbstractMailModel::dataFromItem(item, DateTimeRole).toDateTime();
        if (date.isValid() && (!latestDate.isValid() || date > latestDate)) {
            latestDate = date;
            latestItem = item;
        }

        for (int row = 0; row < m_messageModel->rowCount(itemIndex); ++row) {
            visit(visit, m_messageModel->index(row, 0, itemIndex));
        }
    };
    visit(visit, rootIndex);

    return AbstractMailModel::dataFromItem(latestItem, DateRole);
}

int MailPresentationModel::unreadDescendantCount(const QModelIndex &sourceIndex) const
{
    int unreadCount = 0;
    for (int row = 0; row < m_messageModel->rowCount(sourceIndex); ++row) {
        const auto childIndex = m_messageModel->index(row, 0, sourceIndex);
        const auto item = childIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        Akonadi::MessageStatus status;
        status.setStatusFromFlags(item.flags());
        unreadCount += !status.isRead();
        unreadCount += unreadDescendantCount(childIndex);
    }
    return unreadCount;
}

QStringList MailPresentationModel::threadSenders(const QModelIndex &sourceIndex) const
{
    QStringList senders;
    const auto visit = [&](const auto &visit, const QModelIndex &itemIndex) -> void {
        const auto item = itemIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto sender = AbstractMailModel::dataFromItem(item, FromRole).toString();
        if (!sender.isEmpty() && !senders.contains(sender)) {
            senders.append(sender);
        }

        for (int row = 0; row < m_messageModel->rowCount(itemIndex); ++row) {
            visit(visit, m_messageModel->index(row, 0, itemIndex));
        }
    };
    visit(visit, sourceIndex);
    return senders;
}

void MailPresentationModel::setThreading(MessageList::Core::Aggregation::Threading threading)
{
    if (this->threading() == threading) {
        return;
    }

    m_messageModel->setThreading(threading);
    Q_EMIT threadingChanged();
}

QHash<int, QByteArray> MailPresentationModel::roleNames() const
{
    auto roles = QIdentityProxyModel::roleNames();
    const auto mailRoles = AbstractMailModel::roleNames();
    for (auto it = mailRoles.cbegin(), end = mailRoles.cend(); it != end; ++it) {
        roles.insert(it.key(), it.value());
    }
    return roles;
}

QVariant MailPresentationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    if (role < Akonadi::EntityTreeModel::UserRole) {
        return QIdentityProxyModel::data(index, role);
    }

    const auto sourceIndex = mapToSource(index);
    const auto item = QIdentityProxyModel::data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    if (role == ThreadSectionDateRole) {
        return threadSectionDate(sourceIndex);
    }
    if (role == UnreadDescendantCountRole) {
        return unreadDescendantCount(sourceIndex);
    }
    if (role == IsThreadRootRole) {
        return !sourceIndex.parent().isValid();
    }
    if (role == ThreadSendersRole) {
        return threadSenders(sourceIndex);
    }

    return AbstractMailModel::dataFromItem(item, role);
}
