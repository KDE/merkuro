// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailpresentationmodel.h"

#include <MessageList/MessageModel>

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

    const auto item = QIdentityProxyModel::data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    return AbstractMailModel::dataFromItem(item, role);
}
