// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "threadedmailmodel.h"

ThreadedMailModel::ThreadedMailModel(QObject *const object)
    : QAbstractItemModel(object)
{
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
