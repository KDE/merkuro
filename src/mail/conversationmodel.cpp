// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "conversationmodel.h"

#include "abstractmailmodel.h"
#include "mailpresentationmodel.h"

#include <Akonadi/EntityTreeModel>
#include <Akonadi/MessageStatus>

ConversationModel::ConversationModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

Akonadi::Item ConversationModel::seedItem() const
{
    return m_seedItem;
}

void ConversationModel::setSeedItem(const Akonadi::Item &item)
{
    if (m_seedItem.id() == item.id() && m_seedItem.isValid() == item.isValid()) {
        return;
    }

    m_seedItem = item;
    Q_EMIT seedItemChanged();
    refresh();
}

MailPresentationModel *ConversationModel::folderModel() const
{
    return m_folderModel;
}

void ConversationModel::setFolderModel(MailPresentationModel *model)
{
    if (m_folderModel == model) {
        return;
    }

    m_folderModel = model;

    Q_EMIT folderModelChanged();
    refresh();
}

int ConversationModel::anchorRow() const
{
    return m_anchorRow;
}

int ConversationModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant ConversationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size()) {
        return {};
    }

    const auto &item = m_items.at(index.row());
    if (role == ItemRole) {
        return QVariant::fromValue(item);
    }
    if (role == ItemIdRole) {
        return item.id();
    }

    switch (role) {
    case TitleRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::TitleRole);
    case FromRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::FromRole);
    case SenderRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::SenderRole);
    case ToRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::ToRole);
    case DateTimeRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::DateTimeRole);
    case StatusRole:
        return AbstractMailModel::dataFromItem(item, AbstractMailModel::StatusRole);
    default:
        return {};
    }
}

QHash<int, QByteArray> ConversationModel::roleNames() const
{
    return {
        {ItemRole, "item"},
        {ItemIdRole, "itemId"},
        {TitleRole, "title"},
        {FromRole, "from"},
        {SenderRole, "sender"},
        {ToRole, "to"},
        {DateTimeRole, "datetime"},
        {StatusRole, "status"},
    };
}

void ConversationModel::refresh()
{
    const auto oldAnchor = m_anchorRow;
    beginResetModel();
    m_items = m_folderModel ? m_folderModel->conversationItems(m_seedItem) : Akonadi::Item::List{};
    m_anchorRow = -1;
    for (int row = 0; row < m_items.size(); ++row) {
        if (m_items.at(row).id() == m_seedItem.id()) {
            m_anchorRow = row;
            break;
        }
    }
    endResetModel();

    if (oldAnchor != m_anchorRow) {
        Q_EMIT anchorRowChanged();
    }
}

#include "moc_conversationmodel.cpp"
