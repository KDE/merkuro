// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementQuick/KeyListModelInterface>
#include <Libkleo/KeyListSortFilterProxyModel>
#include <QIdentityProxyModel>

namespace KIdentityManagementCore
{
class Identity;
}

class IdentityKeyListModel : public QIdentityProxyModel, public KIdentityManagementQuick::KeyListModelInterface
{
    Q_OBJECT
    Q_INTERFACES(KIdentityManagementQuick::KeyListModelInterface)

public:
    enum class TypeKeys { AnyTypeKeys, OpenPGPTypeKeys, SMimeTypeKeys };
    Q_ENUM(TypeKeys)

    explicit IdentityKeyListModel(QObject *parent = nullptr, const TypeKeys typeOfKeysToDisplay = TypeKeys::AnyTypeKeys);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    QModelIndex mapToSource(const QModelIndex &index) const override;
    QModelIndex mapFromSource(const QModelIndex &source_index) const override;
    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;

    QModelIndex indexForIdentity(const KIdentityManagementCore::Identity &identity, const KIdentityManagementQuick::KeyUseTypes::KeyUse keyUse) const override;

    [[nodiscard]] QString filterEmail() const;
    void setEmailFilter(const QString &email);

    TypeKeys displayedTypeKeys() const;
    void setDisplayedTypeKeys(const TypeKeys displayedKeyTypes);

private:
    void updateKeyFilter();
    [[nodiscard]] QModelIndex indexForKey(const QByteArray &key) const;

    Kleo::KeyListSortFilterProxyModel *m_baseModel = nullptr;
    TypeKeys m_displayedTypeKeys = TypeKeys::AnyTypeKeys;

    const int m_noKeyRow = 0;
    const int m_customKeyCount = 1;
};
