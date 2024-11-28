// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "threadedmailmodel.h"

#include <KFormat>
#include <KLocalizedString>

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
    QHash<QString, QList<std::shared_ptr<MailItem>>> pendingChildren;

    for (auto i = 0; i < mailCount; ++i) {
        const auto item = m_baseModel->index(i, 0).data(MailModel::ItemRole).value<Akonadi::Item>();
        Q_ASSERT(item.hasPayload<KMime::Message::Ptr>());

        const auto mail = item.payload<KMime::Message::Ptr>();
        const auto mailId = mail->messageID()->asUnicodeString();
        const auto parentId = mail->inReplyTo() ? mail->inReplyTo()->asUnicodeString() : QString();
        const auto parent = m_items.value(parentId);
        const auto children = pendingChildren.take(mailId);

        const auto mailItem = std::make_shared<MailItem>();
        mailItem->item = item;
        mailItem->mail = mail;
        mailItem->parent = parent;
        mailItem->children = children;

        for (const auto &child : children) {
            child->parent = mailItem;
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

    if (parentItem != nullptr && row >= 0 && row < parentItem->children.size()) {
        const auto childItem = parentItem->children.at(row);
        return createIndex(row, column, childItem.get());
    } else if (parentItem != nullptr) {
        qWarning() << "Index has parent item but received an invalid row!" << parent << row << parentItem->children.size();
        return {};
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
            parentFamilyIndex = parentIt - parentSiblings.cbegin();
        }
    }

    return createIndex(parentFamilyIndex, 0, parentItem.get());
}

int ThreadedMailModel::rowCount(const QModelIndex &index) const
{
    if (index.column() > 0) {
        return 0;
    }

    if (index.isValid()) {
        return static_cast<MailItem *>(index.internalPointer())->children.size();
    }

    return m_items.count();
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

    const auto item = static_cast<MailItem *>(index.internalPointer());
    if (item == nullptr) {
        return {};
    }

    const auto mail = item->mail;
    // Static for speed reasons
    static const QString noSubject = i18nc("displayed as subject when the subject of a mail is empty", "No Subject");
    static const QString unknown(i18nc("displayed when a mail has unknown sender, receiver or date", "Unknown"));

    QString subject = mail->subject()->asUnicodeString();
    if (subject.isEmpty()) {
        subject = QLatin1Char('(') + noSubject + QLatin1Char(')');
    }

    /*
     *   MessageStatus stat;
     *   stat.setStatusFromFlags(item.flags());
     */

    switch (role) {
    case TitleRole:
        if (mail->subject()) {
            return mail->subject()->asUnicodeString();
        } else {
            return noSubject;
        }
    case FromRole:
        if (mail->from()) {
            return mail->from()->asUnicodeString();
        } else {
            return QString();
        }
    case SenderRole:
        if (mail->sender()) {
            return mail->sender()->asUnicodeString();
        } else {
            return QString();
        }
    case ToRole:
        if (mail->to()) {
            return mail->to()->asUnicodeString();
        } else {
            return unknown;
        }
    case DateRole:
        if (mail->date()) {
            return KFormat().formatRelativeDate(mail->date()->dateTime().date(), QLocale::LongFormat);
        } else {
            return QString();
        }
    case DateTimeRole:
        if (mail->date()) {
            return mail->date()->dateTime();
        } else {
            return QString();
        }
    case StatusRole:
        return {}; // QVariant::fromValue(stat);
    case ItemRole:
        return QVariant::fromValue(item);
    }
    return {};
}

QHash<int, QByteArray> ThreadedMailModel::roleNames() const
{
    return {
        {TitleRole, QByteArrayLiteral("title")},
        {DateRole, QByteArrayLiteral("date")},
        {DateTimeRole, QByteArrayLiteral("datetime")},
        {SenderRole, QByteArrayLiteral("sender")},
        {FromRole, QByteArrayLiteral("from")},
        {ToRole, QByteArrayLiteral("to")},
        {StatusRole, QByteArrayLiteral("status")},
        {FavoriteRole, QByteArrayLiteral("favorite")},
        {TextColorRole, QByteArrayLiteral("textColor")},
        {BackgroundColorRole, QByteArrayLiteral("backgroudColor")},
        {ItemRole, QByteArrayLiteral("item")},
    };
}
