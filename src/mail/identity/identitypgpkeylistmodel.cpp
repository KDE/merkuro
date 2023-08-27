// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitypgpkeylistmodel.h"

#include <Libkleo/KeyCache>
#include <Libkleo/KeyListModel>

IdentityPGPKeyListModel::IdentityPGPKeyListModel(QObject *parent)
    : QIdentityProxyModel(parent)
{
    const auto flatModel = Kleo::AbstractKeyListModel::createFlatKeyListModel(this);
    const auto keys = Kleo::KeyCache::instance()->keys();
    flatModel->setKeys(keys);
    m_baseModel = new Kleo::KeyListSortFilterProxyModel(this);
    m_baseModel->setSourceModel(flatModel);
    setSourceModel(flatModel);
}
{
}
