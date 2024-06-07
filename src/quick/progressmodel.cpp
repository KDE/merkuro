// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "progressmodel.h"

using namespace Akonadi::Quick;
using namespace KPIM;

ProgressModel::ProgressModel(QObject *const parent)
    : QAbstractListModel(parent)
{
    const auto pm = ProgressManager::instance();
    connect(pm, &ProgressManager::progressItemAdded, this, &ProgressModel::slotProgressItemAdded);
    connect(pm, &ProgressManager::progressItemCompleted, this, &ProgressModel::slotProgressItemCompleted);
}

void ProgressModel::slotProgressItemAdded(KPIM::ProgressItem *const item)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_items.append(item);
    endInsertRows();
}

void ProgressModel::slotProgressItemCompleted(KPIM::ProgressItem *const item)
{
    const auto row = m_items.indexOf(item);
    if (row == -1) {
        return;
    }
    beginRemoveRows(QModelIndex(), row, row);
    m_items.removeAt(row);
    endRemoveRows();
}
