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
        KContacts::Geo geo;
        geo.setLatitude(35.6762);
        geo.setLongitude(139.6503);
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
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::IsEmptyRole).toBool(), false);
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::ExtendedRole), QString());
        QCOMPARE(addressModel.data(addressModel.index(0, 0), AddressModel::PostalCodeRole), QString());

        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::FormattedAddressRole), u"Tokyo\nJapan"_s);
        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::LongitudeRole).toInt(), 140);
        QCOMPARE(addressModel.data(addressModel.index(1, 0), AddressModel::IsEmptyRole).toBool(), false);
    }
};

QTEST_MAIN(AddressModelTest)
#include "addressmodeltest.moc"
