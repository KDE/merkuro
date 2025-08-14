// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "progressmodel.h"

using namespace Akonadi::Quick;
using namespace KPIM;
using namespace Qt::Literals::StringLiterals;
ProgressModel::ProgressModel(QObject *const parent)
    : QAbstractListModel(parent)
{
    const auto pm = ProgressManager::instance();
    connect(pm, &ProgressManager::progressItemAdded, this, &ProgressModel::slotProgressItemAdded);
    connect(pm, &ProgressManager::progressItemCompleted, this, &ProgressModel::slotProgressItemCompleted);
    connect(pm, &ProgressManager::progressItemProgress, this, &ProgressModel::slotProgressItemProgress);
    connect(pm, &ProgressManager::progressItemStatus, this, &ProgressModel::slotProgressItemStatus);
    connect(pm, &ProgressManager::progressItemLabel, this, &ProgressModel::slotProgressItemLabel);
    connect(pm, &ProgressManager::progressItemCryptoStatus, this, &ProgressModel::slotProgressItemCryptoStatus);
    connect(pm, &ProgressManager::progressItemUsesBusyIndicator, this, &ProgressModel::slotProgressItemUsesBusyIndicator);
    connect(pm, &ProgressManager::showProgressDialog, this, &ProgressModel::showProgressView);
}

void ProgressModel::slotProgressItemAdded(KPIM::ProgressItem *const item)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_items.append(item);
    endInsertRows();
    updateOverallProperties();
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
    updateOverallProperties();
}

void ProgressModel::slotProgressItemProgress(KPIM::ProgressItem *const item, const unsigned int progress)
{
    Q_UNUSED(progress)
    slotItemProgressDataChanged(item, {ProgressRole});
}

void ProgressModel::slotProgressItemStatus(KPIM::ProgressItem *const item, const QString &status)
{
    Q_UNUSED(status)
    slotItemProgressDataChanged(item, {StatusRole});
}

void ProgressModel::slotProgressItemLabel(KPIM::ProgressItem *const item, const QString &label)
{
    Q_UNUSED(label)
    slotItemProgressDataChanged(item, {Qt::DisplayRole});
}

void ProgressModel::slotProgressItemCryptoStatus(KPIM::ProgressItem *const item, const KPIM::ProgressItem::CryptoStatus cryptoStatus)
{
    Q_UNUSED(cryptoStatus)
    slotItemProgressDataChanged(item, {CryptoStatusRole});
}

void ProgressModel::slotProgressItemUsesBusyIndicator(KPIM::ProgressItem *const item, const bool usesBusyIndicator)
{
    Q_UNUSED(usesBusyIndicator)
    slotItemProgressDataChanged(item, {UsesBusyIndicatorRole});
}

void ProgressModel::slotItemProgressDataChanged(KPIM::ProgressItem *const item, const QList<int> &roles)
{
    const auto row = m_items.indexOf(item);
    if (row == -1) {
        return;
    }
    const auto idx = index(row);
    Q_EMIT dataChanged(idx, idx, roles);
    updateOverallProperties();
}

int ProgressModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_items.count();
}

QVariant ProgressModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto item = m_items.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
        return item->label();
    case ProgressRole:
        return item->progress();
    case StatusRole:
        return item->status();
    case CanBeCancelledRole:
        return item->canBeCanceled();
    case UsesBusyIndicatorRole:
        return item->usesBusyIndicator();
    case CryptoStatusRole:
        return item->cryptoStatus();
    case IdRole:
        return item->id();
    default:
        return {};
    }
}

QHash<int, QByteArray> ProgressModel::roleNames() const
{
    auto rolenames = QAbstractListModel::roleNames();
    rolenames.insert({
        {ProgressRole, "progress"_ba},
        {StatusRole, "status"_ba},
        {CanBeCancelledRole, "canBeCancelled"_ba},
        {UsesBusyIndicatorRole, "usesBusyIndicator"_ba},
        {CryptoStatusRole, "cryptoStatus"_ba},
        {IdRole, "id"_ba},
    });
    return rolenames;
}

bool ProgressModel::working() const
{
    return m_working;
}

bool ProgressModel::indeterminate() const
{
    return m_indeterminate;
}

unsigned int ProgressModel::progress() const
{
    return m_progress;
}

void ProgressModel::updateOverallProperties()
{
    const auto working = !m_items.isEmpty();
    if (m_working != working) {
        m_working = working;
        Q_EMIT workingChanged();
    }

    const auto indeterminate = m_items.count() > 1;
    if (m_indeterminate != indeterminate) {
        m_indeterminate = indeterminate;
        Q_EMIT indeterminateChanged();
    }

    if (working && !indeterminate) {
        const auto item = m_items.first();
        const auto progress = item != nullptr ? item->progress() : 0;
        if (m_progress != progress) {
            m_progress = progress;
            Q_EMIT progressChanged();
        }
    }
}

void ProgressModel::cancelItem(const QString &itemId)
{
    const auto item = std::find_if(m_items.begin(), m_items.end(), [itemId](const KPIM::ProgressItem *const item) {
        return item->id() == itemId;
    });

    if (item == m_items.end()) {
        qWarning() << "ProgressModel::cancelItem: item not found";
        return;
    }

    (*item)->cancel();
}

#include "moc_progressmodel.cpp"
