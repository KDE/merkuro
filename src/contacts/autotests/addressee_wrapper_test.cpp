// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../addresseewrapper.h"

#include <KContacts/Email>
#include <QSignalSpy>
#include <QTest>

using namespace Qt::Literals::StringLiterals;

class AddresseeWrapperTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void loadsAndSynchronizesContactData()
    {
        KContacts::Addressee addressee;
        addressee.setUid(u"ada-lovelace"_s);
        addressee.setGivenName(u"Ada"_s);
        addressee.setFamilyName(u"Lovelace"_s);
        addressee.setFormattedName(u"Ada Lovelace"_s);
        KContacts::Email email(u"ada@example.org"_s);
        email.setPreferred(true);
        addressee.setEmailList({email});

        KContacts::PhoneNumber phone(u"+49 123 456"_s);
        addressee.insertPhoneNumber(phone);

        AddresseeWrapper wrapper;
        wrapper.setAddressee(addressee);

        QCOMPARE(wrapper.uid(), u"ada-lovelace"_s);
        QCOMPARE(wrapper.formattedName(), u"Ada Lovelace"_s);
        QCOMPARE(wrapper.preferredEmail(), u"ada@example.org"_s);
        QCOMPARE(wrapper.emailModel()->rowCount(), 1);
        QCOMPARE(wrapper.phoneModel()->rowCount(), 1);

        QSignalSpy nameChanged(&wrapper, &AddresseeWrapper::formattedNameChanged);
        wrapper.setFormattedName(u"Ada Byron Lovelace"_s);
        QCOMPARE(nameChanged.count(), 1);
        QCOMPARE(wrapper.formattedName(), u"Ada Byron Lovelace"_s);
        QCOMPARE(wrapper.givenName(), u"Ada"_s);
        QCOMPARE(wrapper.familyName(), u"Lovelace"_s);

        wrapper.emailModel()->addEmail(u"ada@kde.org"_s, EmailModel::Work);
        QCOMPARE(wrapper.addressee().emails().size(), 2);
        QVERIFY(wrapper.addressee().emails().contains(u"ada@kde.org"_s));
    }

    void serializesToQrCodeData()
    {
        KContacts::Addressee addressee;
        addressee.setName(u"Grace Hopper"_s);
        KContacts::Email email(u"grace@example.org"_s);
        email.setPreferred(true);
        addressee.setEmailList({email});

        AddresseeWrapper wrapper;
        wrapper.setAddressee(addressee);

        const auto qrCodeData = wrapper.qrCodeData();
        QVERIFY(qrCodeData.contains(u"Grace Hopper"_s));
        QVERIFY(qrCodeData.contains(u"grace@example.org"_s));
    }

    void addressEditsAreStoredInTheContact()
    {
        AddresseeWrapper wrapper;
        KContacts::Addressee addressee;
        KContacts::Address original(KContacts::Address::Home);
        original.setStreet(u"First Street"_s);
        addressee.setAddresses({original});
        wrapper.setAddressee(addressee);

        KContacts::Address second(KContacts::Address::Work);
        second.setStreet(u"Second Street"_s);
        wrapper.addressesModel()->addAddress(second);
        QCOMPARE(wrapper.addressee().addresses().size(), 2);
        QCOMPARE(wrapper.addressee().addresses().at(1).street(), u"Second Street"_s);

        auto updated = wrapper.addressesModel()->addressAt(0);
        updated.setStreet(u"Updated Street"_s);
        wrapper.addressesModel()->updateAddress(0, updated);
        QCOMPARE(wrapper.addressee().addresses().at(0).street(), u"Updated Street"_s);

        wrapper.addressesModel()->deleteAddress(1);
        QCOMPARE(wrapper.addressee().addresses().size(), 1);
    }

    void photoUrlUsesLibravatarOnlyWithoutContactPhoto()
    {
        AddresseeWrapper wrapper;
        QCOMPARE(wrapper.photoUrl(), QString());

        KContacts::Addressee addressee;
        KContacts::Email email(u"ada@example.org"_s);
        email.setPreferred(true);
        addressee.setEmailList({email});
        wrapper.setAddressee(addressee);
        QCOMPARE(wrapper.photoUrl(), u"image://contact/ada@example.org"_s);

        KContacts::Picture photo;
        photo.setUrl(u"https://example.org/ada.png"_s);
        addressee.setPhoto(photo);
        wrapper.setAddressee(addressee);
        QCOMPARE(wrapper.photoUrl(), u"https://example.org/ada.png"_s);
    }
};

QTEST_MAIN(AddresseeWrapperTest)

#include "addressee_wrapper_test.moc"
