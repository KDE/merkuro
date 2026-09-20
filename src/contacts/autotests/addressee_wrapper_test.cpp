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
};

QTEST_MAIN(AddresseeWrapperTest)

#include "addressee_wrapper_test.moc"
