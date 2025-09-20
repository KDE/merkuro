// SPDX-FileCopyrightText: 2024 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QVariant>

namespace Akonadi
{
class Item;
}

class AbstractMailModel
{
public:
    enum ExtraRole {
        TitleRole = Qt::UserRole + 1,
        SenderRole,
        FromRole,
        ToRole,
        TextColorRole,
        DateRole,
        DateTimeRole,
        BackgroundColorRole,
        StatusRole,
        FavoriteRole,
        ItemRole,
    };

    QVariant dataFromItem(const Akonadi::Item &item, int role) const;
    QHash<int, QByteArray> roleNames() const;
};
