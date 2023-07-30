// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QSortFilterProxyModel>

namespace Kleo
{
namespace Quick
{

class KeyComboBoxModel : public QSortFilterProxyModel
{
public:
    explicit KeyComboBoxModel(QObject *parent = nullptr);
};

}

}
