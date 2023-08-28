// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <Libkleo/KeyListSortFilterProxyModel>
#include <QIdentityProxyModel>

class IdentityKeyListModel : public QIdentityProxyModel
{
    Q_OBJECT

public:
    enum class TypeKeys { AnyTypeKeys, OpenPGPTypeKeys, SMimeTypeKeys };
    Q_ENUM(TypeKeys)

    explicit IdentityKeyListModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    QModelIndex mapToSource(const QModelIndex &index) const override;
    QModelIndex mapFromSource(const QModelIndex &source_index) const override;
    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;

    QString filterEmail() const;
    void setEmailFilter(const QString &email);

    TypeKeys displayedTypeKeys() const;
    void setDisplayedTypeKeys(const TypeKeys displayedKeyTypes);

private:
    void updateKeyFilter();

    Kleo::KeyListSortFilterProxyModel *m_baseModel = nullptr;
    TypeKeys m_displayedTypeKeys = TypeKeys::AnyTypeKeys;

    const int m_noKeyRow = 0;
    const int m_customKeyCount = 1;
};
