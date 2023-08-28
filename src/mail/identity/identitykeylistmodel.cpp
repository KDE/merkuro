// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitykeylistmodel.h"

#include <KIdentityManagement/KeyListModel>
#include <KLocalizedString>
#include <Libkleo/DefaultKeyFilter>
#include <Libkleo/KeyCache>
#include <Libkleo/KeyListModel>
#include <gpgme++/key.h>

IdentityKeyListModel::IdentityKeyListModel(QObject *parent, const TypeKeys typeOfKeysToDisplay)
    : QIdentityProxyModel(parent)
{
    const auto flatModel = Kleo::AbstractKeyListModel::createFlatKeyListModel(this);
    const auto keys = Kleo::KeyCache::instance()->keys();
    flatModel->setKeys(keys);
    m_baseModel = new Kleo::KeyListSortFilterProxyModel(this);
    m_baseModel->setSourceModel(flatModel);
    setSourceModel(m_baseModel);

    setDisplayedTypeKeys(typeOfKeysToDisplay);
}

QVariant IdentityKeyListModel::data(const QModelIndex &index, int role) const
{
    if (index.row() == 0) {
        switch (role) {
        case Qt::DisplayRole:
            return i18n("No key");
        default:
            return {};
        }
    }

    switch (role) {
    case KIdentityManagement::Quick::KeyListModel::Roles::KeyByteArrayRole:
        return QByteArray(m_baseModel->key(mapToSource(index)).primaryFingerprint());
    case KIdentityManagement::Quick::KeyListModel::Roles::KeyIdentifierRole:
        return QByteArray(m_baseModel->key(mapToSource(index)).keyID());
    }

    return QIdentityProxyModel::data(index, role);
}

QHash<int, QByteArray> IdentityKeyListModel::roleNames() const
{
    auto names = QIdentityProxyModel::roleNames();
    names.insert(KIdentityManagement::Quick::KeyListModel::roleNames());
    return names;
}

int IdentityKeyListModel::rowCount(const QModelIndex &parent) const
{
    return QIdentityProxyModel::rowCount(parent) + m_customKeyCount;
}

QModelIndex IdentityKeyListModel::mapToSource(const QModelIndex &index) const
{
    if (!index.isValid()) {
        return {};
    } else if (index.row() != m_noKeyRow) {
        const auto sourceRow = index.row() - m_customKeyCount;
        return QIdentityProxyModel::mapToSource(createIndex(sourceRow, index.column(), index.internalPointer()));
    }
    return {};
}

QModelIndex IdentityKeyListModel::mapFromSource(const QModelIndex &source_index) const
{
    const QModelIndex idx = QIdentityProxyModel::mapFromSource(source_index);
    return createIndex(m_customKeyCount + idx.row(), idx.column(), idx.internalPointer());
}

QModelIndex IdentityKeyListModel::index(int row, int column, const QModelIndex &parent) const
{
    if (row < 0 || row >= rowCount()) {
        return {};
    } else if (row == m_noKeyRow) {
        return createIndex(row, column, nullptr);
    } else {
        const auto index = QIdentityProxyModel::index(row - m_customKeyCount, column, parent);
        return createIndex(row, column, index.internalPointer());
    }
}

QString IdentityKeyListModel::filterEmail() const
{
    if (!m_baseModel) {
        return {};
    }
    return m_baseModel->filterRegularExpression().pattern();
}

void IdentityKeyListModel::setEmailFilter(const QString &email)
{
    if (!m_baseModel) {
        return;
    }
    m_baseModel->setFilterRegularExpression(email);
}

IdentityKeyListModel::TypeKeys IdentityKeyListModel::displayedTypeKeys() const
{
    return m_displayedTypeKeys;
}

void IdentityKeyListModel::setDisplayedTypeKeys(const TypeKeys displayedTypeKeys)
{
    if (!m_baseModel || m_displayedTypeKeys == displayedTypeKeys) {
        return;
    }
    m_displayedTypeKeys = displayedTypeKeys;
    updateKeyFilter();
}

void IdentityKeyListModel::updateKeyFilter()
{
    const auto keyFilter = std::make_shared<Kleo::DefaultKeyFilter>();

    switch (m_displayedTypeKeys) {
    case TypeKeys::AnyTypeKeys:
        keyFilter->setValidIfSMIME(Kleo::DefaultKeyFilter::Set);
        keyFilter->setIsOpenPGP(Kleo::DefaultKeyFilter::Set);
        break;
    case TypeKeys::OpenPGPTypeKeys:
        keyFilter->setValidIfSMIME(Kleo::DefaultKeyFilter::NotSet);
        keyFilter->setIsOpenPGP(Kleo::DefaultKeyFilter::Set);
        break;
    case TypeKeys::SMimeTypeKeys:
        keyFilter->setValidIfSMIME(Kleo::DefaultKeyFilter::Set);
        keyFilter->setIsOpenPGP(Kleo::DefaultKeyFilter::NotSet);
        break;
    }

    m_baseModel->setKeyFilter(keyFilter);
}
