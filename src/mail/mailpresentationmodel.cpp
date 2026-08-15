// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailpresentationmodel.h"

#include <MessageList/MessageModel>
#include <QDateTime>

MailPresentationModel::MailPresentationModel(QObject *parent)
    : QIdentityProxyModel(parent)
    , m_messageModel(std::make_unique<MessageList::MessageModel>(this))
{
    setSourceModel(m_messageModel.get());
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

    return AbstractMailModel::dataFromItem(item, role);
}
