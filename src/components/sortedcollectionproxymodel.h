// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/CollectionFilterProxyModel>

#include <merkurocomponents_export.h>

class MERKUROCOMPONENTS_EXPORT SortedCollectionProxModel : public Akonadi::CollectionFilterProxyModel
{
public:
    explicit SortedCollectionProxModel(QObject *parent = nullptr);

protected:
    [[nodiscard]] bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;
};
