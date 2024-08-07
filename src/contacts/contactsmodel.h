// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/EntityTreeModel>
#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

/// Contacts model with an email addreess
class ContactsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum ExtraRoles {
        EmailRole = Akonadi::EntityTreeModel::UserRole + 1,
        AllEmailsRole,
        GidRole,
    };
    Q_ENUM(ExtraRoles)
    explicit ContactsModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override;
};
