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
    const auto parentItem = parent.isValid() ? static_cast<MailItem *>(parent.internalPointer()) : nullptr;

    if (parentItem != nullptr) {
        const auto childItemPtr = parentItem->children.at(row);
        const auto childItem = childItemPtr.lock();
        return createIndex(row, column, childItem.get());
    }

    if (row < 0 || row >= m_orderedIds.count()) {
        return {};
    }

    const auto id = m_orderedIds.at(row);
    if (const auto childItem = m_items.value(id)) {
        return createIndex(row, column, childItem.get());
    }
    return {};
}

QModelIndex ThreadedMailModel::parent(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return {};
    }

    const auto childItem = static_cast<MailItem *>(index.internalPointer());
    const auto parentItemPtr = childItem->parent;
    const auto parentItem = parentItemPtr.lock();
    if (parentItem == nullptr) {
        return {};
    }

    const auto parentId = parentItem->mail->messageID()->asUnicodeString();
    const auto grandParentPtr = parentItem->parent;
    const auto grandParent = grandParentPtr.lock();
    auto parentFamilyIndex = -1;

    if (grandParent.get() == nullptr) {
        const auto parentIt = std::find(m_orderedIds.cbegin(), m_orderedIds.cend(), parentId);
        if (parentIt != m_orderedIds.cend()) {
            parentFamilyIndex = parentIt - m_orderedIds.cbegin();
        }
    } else {
        const auto parentSiblings = grandParent->children;
        const auto parentIt = std::find_if(parentSiblings.cbegin(), parentSiblings.cend(), [&parentId](const std::weak_ptr<MailItem> item) {
            return item.lock()->mail->messageID()->asUnicodeString() == parentId;
        });
        if (parentIt != parentSiblings.cend()) {
            parentFamilyIndex = parentIt - parentSiblings.cend();
        }
    }

    return createIndex(parentFamilyIndex, 0, parentItem.get());
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
