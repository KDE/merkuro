// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailmodel.h"

#include <Akonadi/ItemModifyJob>
#include <Akonadi/MessageStatus>
#include <Akonadi/SelectionProxyModel>
#include <KLocalizedString>
#include <KMime/Message>

MailModel::MailModel(QObject *parent)
    : Akonadi::EntityMimeTypeFilterModel(parent)
{
    setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);
    addMimeTypeInclusionFilter(KMime::Message::mimeType());
    addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());
}

QHash<int, QByteArray> MailModel::roleNames() const
{
    return AbstractMailModel::roleNames();
}

QVariant MailModel::data(const QModelIndex &index, int role) const
{
    const QVariant itemVariant = sourceModel()->data(mapToSource(index), Akonadi::EntityTreeModel::ItemRole);
    const Akonadi::Item item = itemVariant.value<Akonadi::Item>();
    return AbstractMailModel::dataFromItem(item, role);
}

Akonadi::Item MailModel::itemForRow(int row) const
{
    return data(index(row, 0), ItemRole).value<Akonadi::Item>();
}

Akonadi::EntityTreeModel *MailModel::entryTreeModel() const
{
    return m_entityTreeModel;
}

void MailModel::setEntityTreeModel(Akonadi::EntityTreeModel *entityTreeModel)
{
    if (m_entityTreeModel == entityTreeModel) {
        return;
    }

    m_entityTreeModel = entityTreeModel;
    Q_EMIT entityTreeModelChanged();

    if (!m_entityTreeModel) {
        return;
    }
    setupModel();
}

QItemSelectionModel *MailModel::collectionSelectionModel() const
{
    return m_collectionSelectionModel;
}

void MailModel::setCollectionSelectionModel(QItemSelectionModel *collectionSelectionModel)
{
    if (m_collectionSelectionModel == collectionSelectionModel) {
        return;
    }

    m_collectionSelectionModel = collectionSelectionModel;
    Q_EMIT collectionSelectionModelChanged();

    if (!m_collectionSelectionModel) {
        return;
    }
    setupModel();

    connect(m_collectionSelectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
        Q_UNUSED(deselected)
        const auto indexes = selected.indexes();
        if (indexes.isEmpty()) {
            return;
        }
        QString name;
        QModelIndex index = indexes[0];
        while (index.isValid()) {
            if (name.isEmpty()) {
                name = index.data(Qt::DisplayRole).toString();
            } else {
                name = index.data(Qt::DisplayRole).toString() + QLatin1StringView(" / ") + name;
            }
            index = index.parent();
        }
        m_folderName = name;
        Q_EMIT folderNameChanged();
    });
}

void MailModel::setupModel()
{
    if (!m_collectionSelectionModel || !m_entityTreeModel) {
        return;
    }

    auto selectionModel = new Akonadi::SelectionProxyModel(m_collectionSelectionModel, this);
    selectionModel->setSourceModel(m_entityTreeModel);
    selectionModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    // Setup mail model
    setSourceModel(selectionModel);

    if (m_showUnreadOnly) {
        captureUnreadSnapshot();
    }
}

bool MailModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!Akonadi::EntityMimeTypeFilterModel::filterAcceptsRow(sourceRow, sourceParent)) {
        return false;
    }
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    const auto item = idx.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    if (m_showUnreadOnly) {
        Akonadi::MessageStatus stat;
        stat.setStatusFromFlags(item.flags());
        if (stat.isRead() && !m_unreadSnapshot.contains(item.id())) {
            return false;
        }
    }
    return true;
}

bool MailModel::showUnreadOnly() const
{
    return m_showUnreadOnly;
}

void MailModel::setShowUnreadOnly(bool showUnreadOnly)
{
    if (m_showUnreadOnly == showUnreadOnly) {
        return;
    }
    m_showUnreadOnly = showUnreadOnly;
    if (m_showUnreadOnly) {
        captureUnreadSnapshot();
    } else {
        m_unreadSnapshot.clear();
    }
    Q_EMIT showUnreadOnlyChanged();
    invalidateFilter();
}

void MailModel::captureUnreadSnapshot()
{
    m_unreadSnapshot.clear();
    const int rows = rowCount();
    for (int i = 0; i < rows; ++i) {
        const auto item = data(index(i, 0), ItemRole).value<Akonadi::Item>();
        if (!item.isValid()) {
            continue;
        }
        Akonadi::MessageStatus stat;
        stat.setStatusFromFlags(item.flags());
        if (!stat.isRead()) {
            m_unreadSnapshot.insert(item.id());
        }
    }
}

QString MailModel::folderName() const
{
    return m_folderName;
}

#include "moc_mailmodel.cpp"
