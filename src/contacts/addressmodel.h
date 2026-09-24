// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Address>
#include <QAbstractListModel>
#include <qqmlregistration.h>

#include "merkuro_contact_export.h"

class MERKURO_CONTACT_EXPORT AddressModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        CountryRole = Qt::UserRole + 1,
        ExtendedRole,
        FormattedAddressRole,
        HasGeoRole,
        LatitudeRole,
        LongitudeRole,
        IdRole,
        IsEmptyRole,
        LabelRole,
        PostalCodeRole,
        PostOfficeBoxRole,
        RegionRole,
        StreetRole,
        TypeRole,
        TypeLabelRole,
        GeoUriRole,
    };
    Q_ENUM(Roles)

    enum Type {
        Other = 0,
        Domestic = KContacts::Address::Dom,
        International = KContacts::Address::Intl,
        Postal = KContacts::Address::Postal,
        Parcel = KContacts::Address::Parcel,
        Home = KContacts::Address::Home,
        Work = KContacts::Address::Work,
        Preferred = KContacts::Address::Pref,
    };
    Q_ENUM(Type)

    explicit AddressModel(QObject *parent = nullptr);

    void setAddresses(const KContacts::Address::List &addresses);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE KContacts::Address addressAt(int row) const;
    Q_INVOKABLE void addAddress(const KContacts::Address &address);
    Q_INVOKABLE void updateAddress(int row, const KContacts::Address &address);
    Q_INVOKABLE void deleteAddress(int row);

Q_SIGNALS:
    void changed(const KContacts::Address::List &addresses);

private:
    KContacts::Address::List m_addresses;
};
