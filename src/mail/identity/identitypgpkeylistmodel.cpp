// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitypgpkeylistmodel.h"

#include <KIdentityManagement/KeyListModel>
#include <Libkleo/KeyCache>
#include <Libkleo/KeyListModel>
#include <gpgme++/key.h>

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

QVariant IdentityPGPKeyListModel::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case KIdentityManagement::Quick::KeyListModel::Roles::KeyByteArrayRole:
        return QByteArray(m_baseModel->key(mapToSource(index)).primaryFingerprint());
    case KIdentityManagement::Quick::KeyListModel::Roles::KeyIdentifierRole:
        return QByteArray(m_baseModel->key(mapToSource(index)).keyID());
    }

    return QIdentityProxyModel::data(index, role);
}

QHash<int, QByteArray> IdentityPGPKeyListModel::roleNames() const
{
    auto names = QIdentityProxyModel::roleNames();
    names.insert(KIdentityManagement::Quick::KeyListModel::roleNames());
    return names;
}
