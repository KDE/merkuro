// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "utils.h"

Utils::Utils(QObject *parent)
    : QObject(parent)
{
}

QModelIndexList Utils::indexesFromSelection(const QItemSelection &selection)
{
    return selection.indexes();
}

#include "moc_utils.cpp"
