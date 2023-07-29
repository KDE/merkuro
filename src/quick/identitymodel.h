// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <KIdentityManagement/IdentityManager>
#include <QAbstractListModel>

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{
class IdentityModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles { EmailRole = Qt::UserRole, UoidRole, IdentityNameRole };

public:
    IdentityModel(QObject *parent = nullptr);
    ~IdentityModel();
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QString email(uint uoid);

private Q_SLOTS:
    void reloadUoidList();

private:
    QList<int> m_identitiesUoid;
    IdentityManager *const m_identityManager;
};
}
}
