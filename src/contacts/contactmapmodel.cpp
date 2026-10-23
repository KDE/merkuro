// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactmapmodel.h"

#include <Akonadi/EntityTreeModel>
#include <KContacts/Addressee>
#include <QGeoCoordinate>

namespace
{
QGeoCoordinate coordinate(const QModelIndex &index)
{
    const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    if (!item.hasPayload<KContacts::Addressee>()) {
        return {};
    }
    const auto contact = item.payload<KContacts::Addressee>();
    const auto toCoordinate = [](const KContacts::Geo &geo) {
        return geo.isValid() ? QGeoCoordinate(geo.latitude(), geo.longitude()) : QGeoCoordinate();
    };
    const auto geo = toCoordinate(contact.geo());
    if (geo.isValid()) {
        return geo;
    }
    const auto addresses = contact.addresses();
    for (const auto &address : addresses) {
        const auto geo = toCoordinate(address.geo());
        if (geo.isValid()) {
            return geo;
        }
    }
    return {};
}
}

ContactMapModel::ContactMapModel(QObject *parent)
    : ContactListProxyModel(parent)
{
    connect(this, &QAbstractItemModel::rowsInserted, this, &ContactMapModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ContactMapModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ContactMapModel::countChanged);
    connect(this, &QAbstractItemModel::dataChanged, this, [this](const QModelIndex &first, const QModelIndex &last, const QList<int> &roles) {
        if (roles.contains(Akonadi::EntityTreeModel::ItemRole)) {
            Q_EMIT dataChanged(first, last, {CoordinateRole, FullNameRole});
        }
    });
}

int ContactMapModel::count() const
{
    return rowCount();
}

QVariant ContactMapModel::data(const QModelIndex &index, int role) const
{
    if (role == CoordinateRole) {
        return QVariant::fromValue(coordinate(mapToSource(index)));
    }
    return ContactListProxyModel::data(index, role);
}

QHash<int, QByteArray> ContactMapModel::roleNames() const
{
    auto roles = ContactListProxyModel::roleNames();
    roles.insert(CoordinateRole, "contactCoordinate");
    return roles;
}

bool ContactMapModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    return coordinate(sourceModel()->index(sourceRow, 0, sourceParent)).isValid() && ContactListProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

#include "moc_contactmapmodel.cpp"
