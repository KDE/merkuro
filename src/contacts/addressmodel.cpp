// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "addressmodel.h"
using namespace Qt::Literals::StringLiterals;
AddressModel::AddressModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AddressModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_addresses.count();
}

QVariant AddressModel::data(const QModelIndex &idx, int role) const
{
    if (!checkIndex(idx)) {
        return {};
    }

    const auto &address = m_addresses[idx.row()];
    switch (role) {
    case CountryRole:
        return address.country();
    case ExtendedRole:
        return address.extended();
    case FormattedAddressRole:
        return address.formatted(KContacts::AddressFormatStyle::MultiLineInternational);
    case HasGeoRole:
        return address.geo().isValid();
    case LongitudeRole:
        return address.geo().longitude();
    case LatitudeRole:
        return address.geo().latitude();
    case IdRole:
        return address.id();
    case IsEmptyRole:
        return address.isEmpty();
    case LabelRole:
        return address.label();
    case PostalCodeRole:
        return address.postalCode();
    case PostOfficeBoxRole:
        return address.postOfficeBox();
    case RegionRole:
        return address.region();
    case StreetRole:
        return address.street();
    case TypeRole:
        return QVariant::fromValue(address.type());
    case TypeLabelRole:
        return address.typeLabel();
    case GeoUriRole:
        return address.geoUri();
    default:
        return {};
    }
}

QHash<int, QByteArray> AddressModel::roleNames() const
{
    return {
        {CountryRole, "country"_ba},
        {ExtendedRole, "extended"_ba},
        {FormattedAddressRole, "formattedAddress"_ba},
        {HasGeoRole, "hasGeo"_ba},
        {LatitudeRole, "latitude"_ba},
        {LongitudeRole, "longitude"_ba},
        {IdRole, "id"_ba},
        {IsEmptyRole, "isEmpty"_ba},
        {LabelRole, "label"_ba},
        {PostalCodeRole, "postalCode"_ba},
        {PostOfficeBoxRole, "postOfficeBox"_ba},
        {RegionRole, "region"_ba},
        {StreetRole, "street"_ba},
        {TypeRole, "type"_ba},
        {TypeLabelRole, "typeLabel"_ba},
        {GeoUriRole, "geoUri"_ba},
    };
}

void AddressModel::setAddresses(const KContacts::Address::List &addresses)
{
    beginResetModel();
    m_addresses = addresses;
    endResetModel();
}

KContacts::Address AddressModel::addressAt(int row) const
{
    return hasIndex(row, 0) ? m_addresses.at(row) : KContacts::Address();
}

void AddressModel::addAddress(const KContacts::Address &address)
{
    const int row = m_addresses.size();
    beginInsertRows({}, row, row);
    m_addresses.append(address);
    endInsertRows();
    Q_EMIT changed(m_addresses);
}

void AddressModel::updateAddress(int row, const KContacts::Address &address)
{
    if (!hasIndex(row, 0)) {
        return;
    }

    auto updated = address;
    // KContacts::Address currently drops Geo when its shared data is detached.
    updated.setGeo(m_addresses.at(row).geo());
    m_addresses[row] = updated;
    Q_EMIT dataChanged(index(row, 0), index(row, 0));
    Q_EMIT changed(m_addresses);
}

void AddressModel::deleteAddress(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }

    beginRemoveRows({}, row, row);
    m_addresses.removeAt(row);
    endRemoveRows();
    Q_EMIT changed(m_addresses);
}

#include "moc_addressmodel.cpp"
