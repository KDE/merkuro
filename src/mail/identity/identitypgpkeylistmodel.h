// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <Libkleo/KeyListSortFilterProxyModel>
#include <QIdentityProxyModel>

class IdentityPGPKeyListModel : public QIdentityProxyModel
{
    Q_OBJECT

public:
    explicit IdentityPGPKeyListModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filterEmail() const;
    void setEmailFilter(const QString &email);

private:
    Kleo::KeyListSortFilterProxyModel *m_baseModel = nullptr;
};
