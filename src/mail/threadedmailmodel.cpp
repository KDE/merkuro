// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "threadedmailmodel.h"

#include "mailmodel.h"

ThreadedMailModel::ThreadedMailModel(QObject *const object, MailModel *const mailModel)
    : QAbstractItemModel(object)
    , m_baseModel(mailModel)
{
    connect(mailModel, &MailModel::rowsInserted, this, &ThreadedMailModel::updateThreading);
    connect(mailModel, &MailModel::rowsRemoved, this, &ThreadedMailModel::updateThreading);
    connect(mailModel, &MailModel::modelReset, this, &ThreadedMailModel::updateThreading);
    updateThreading();
}

void ThreadedMailModel::updateThreading()
{
    beginResetModel();

    m_items.clear();
    m_orderedIds.clear();

    Q_ASSERT(m_baseModel);
    const auto mailCount = m_baseModel->rowCount();
    QHash<QString, QList<std::weak_ptr<MailItem>>> pendingChildren;

    for (auto i = 0; i < mailCount; ++i) {
        const auto item = m_baseModel->index(i, 0).data(MailModel::ItemRole).value<Akonadi::Item>();
        if (!item.hasPayload<KMime::Message::Ptr>()) {
            continue;
        }

        const auto mail = item.payload<KMime::Message::Ptr>();
        const auto mailId = mail->messageID()->asUnicodeString();
        const auto parentId = mail->inReplyTo()->asUnicodeString();
        const auto parent = m_items.value(parentId);
        const auto children = pendingChildren.take(mailId);

        const auto mailItem = std::make_shared<MailItem>();
        mailItem->mail = mail;
        mailItem->parent = parent;
        mailItem->children = children;

        for (const auto &childPtr : children) {
            childPtr.lock()->parent = mailItem;
        }

        if (parent == nullptr && !parentId.isEmpty()) {
            auto parentChildren = pendingChildren.value(parentId);
            parentChildren.append(mailItem);
            pendingChildren.insert(parentId, parentChildren);
        } else if (parent == nullptr) {
            m_orderedIds.append(mailId);
        }

        m_items.insert(mailId, mailItem);
    }

    endResetModel();
}

QModelIndex ThreadedMailModel::index(const int row, const int column, const QModelIndex &parent) const
{
    return {};
}

QModelIndex ThreadedMailModel::parent(const QModelIndex &index) const
{
    return {};
}

int ThreadedMailModel::rowCount(const QModelIndex &index) const
{
    return 0;
}

int ThreadedMailModel::columnCount(const QModelIndex &index) const
{
    Q_UNUSED(index);
    return 1;
}

QVariant ThreadedMailModel::data(const QModelIndex &index, const int role) const
{
    if (!checkIndex(index)) {
        return {};
    }
    return {};
}

QHash<int, QByteArray> ThreadedMailModel::roleNames() const
{
    return {};
}
