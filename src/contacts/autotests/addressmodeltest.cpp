// SPDX-FileCopyrightText: (C) 2023 Anant Verma <vermainfinite@gmail.com>
// SPDX-License-Identifier: BSD-2-Clause

#include "../addressmodel.h"
#include <KContacts/Address>
#include <KLocalizedString>
#include <QObject>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class AddressModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        // Create some addresses
        KContacts::Address address1;
        address1.setCountry(u"India"_s);
        address1.setLabel(u"India"_s);

        KContacts::Address address2;
        KContacts::Geo geo(35.6762f, 139.6503f);
        address2.setCountry(u"Japan"_s);
        address2.setLocality(u"Tokyo"_s);
        address2.setLabel(u"Tokyo"_s);
        address2.setGeo(geo);

        // append to addressList
        KContacts::Address::List addressList;

        addressList.append(address1);
        addressList.append(address2);

        // store it in AddressModel
        AddressModel addressModel;
        addressModel.setAddresses(addressList);

        // run tests
        QCOMPARE(addressModel.rowCount(), 2);
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::CountryRole).toString(), u"India"_s);
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::GeoUriRole).toUrl(), address1.geoUri());
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::IsEmptyRole).toBool(), false);
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::ExtendedRole), QString());
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::PostalCodeRole), QString());

        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::FormattedAddressRole), u"Tokyo\nJapan"_s);
        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::LongitudeRole).toInt(), 140);
        QVERIFY(addressModel.data(addressModel.index(1, 0), AddressModel::HasGeoRole).toBool());
        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::GeoUriRole).toUrl(), address2.geoUri());
        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::IsEmptyRole).toBool(), false);
    }

    void testAddEditAndRemove()
    {
        KContacts::Address original(KContacts::Address::Home | KContacts::Address::Postal);
        original.setId(u"original-address"_s);
        original.setStreet(u"Old Street 1"_s);
        KContacts::Geo geo(35.6762f, 139.6503f);
        original.setGeo(geo);
        QVERIFY(original.geo().isValid());

        AddressModel model;
        model.setAddresses({original});
        QVERIFY(model.addressAt(0).geo().isValid());

        KContacts::Address second(KContacts::Address::Work);
        second.setStreet(u"Second Street 2"_s);
        second.setLocality(u"Berlin"_s);
        model.addAddress(second);
        QVERIFY(model.addressAt(0).geo().isValid());
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.data(model.index(1, 0), AddressModel::StreetRole).toString(), u"Second Street 2"_s);
        QCOMPARE(model.addressAt(1).type(), KContacts::Address::Type(KContacts::Address::Work));

        auto updated = model.addressAt(0);
        QVERIFY(updated.geo().isValid());
        updated.setType((updated.type() & ~KContacts::Address::Home) | KContacts::Address::Work);
        updated.setStreet(u"New Street 3"_s);
        updated.setLocality(u"Tokyo"_s);
        updated.setCountry(u"Japan"_s);
        model.updateAddress(0, updated);
        QCOMPARE(model.data(model.index(0, 0), AddressModel::StreetRole).toString(), u"New Street 3"_s);
        QCOMPARE(model.data(model.index(0, 0), AddressModel::IdRole).toString(), u"original-address"_s);
        QCOMPARE(model.data(model.index(0, 0), AddressModel::HasGeoRole).toBool(), true);
        QCOMPARE(model.addressAt(0).type(), KContacts::Address::Type(KContacts::Address::Work | KContacts::Address::Postal));

        model.deleteAddress(1);
        QCOMPARE(model.rowCount(), 1);
        model.deleteAddress(9);
        QCOMPARE(model.rowCount(), 1);
    }
};

QTEST_MAIN(AddressModelTest)
#include "addressmodeltest.moc"
