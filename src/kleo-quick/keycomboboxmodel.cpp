// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "keycomboboxmodel.h"

#include <Libkleo/KeyListModel>

namespace Kleo
{
namespace Quick
{

KeyComboBoxModel::KeyComboBoxModel(QObject *parent)
    : QSortFilterProxyModel{parent}
{

}

}

}
