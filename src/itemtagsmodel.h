// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <QObject>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/Item>
#else
#include <AkonadiCore/Item>
#endif
#include <QAbstractListModel>

class ItemTagsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem NOTIFY itemChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        IdRole,
    };
    Q_ENUM(Roles);

    ItemTagsModel(QObject *parent = nullptr);
    ~ItemTagsModel() override = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Akonadi::Item item() const;
    void setItem(Akonadi::Item item);

Q_SIGNALS:
    void itemChanged();

private:
    Akonadi::Item m_item;
};
