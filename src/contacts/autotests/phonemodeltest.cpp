// SPDX-FileCopyrightText: (C) 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: BSD-2-Clause

#include "../phonemodel.h"
#include <KContacts/PhoneNumber>
#include <KLocalizedString>
#include <QObject>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class PhoneModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KContacts::Addressee addressee;
        KContacts::PhoneNumber::List phonenumbers;
        phonenumbers.append(KContacts::PhoneNumber(u"+49 721 605605-0"_s));
        phonenumbers.append(KContacts::PhoneNumber(u"+91 80 2361 1974"_s));

        // Creating the phoneModel and loading the initial data
        addressee.setPhoneNumbers(phonenumbers);
        PhoneModel phoneModel;
        phoneModel.loadContact(addressee);
        QModelIndex zeroIndex = phoneModel.index(0, 0);
        int role = PhoneModel::PhoneNumberRole;
        QString phoneNumber1 = phoneModel.data(zeroIndex, role).toString();

        QCOMPARE(phoneModel.rowCount(), 2);
        QCOMPARE(phoneNumber1, u"+49 721 605605-0"_s);

        // Adding a new phone number
        phonenumbers.append(KContacts::PhoneNumber(u"+34 691 86 06 75"_s));
        addressee.setPhoneNumbers(phonenumbers);
        phoneModel.loadContact(addressee);
        QModelIndex secondIndex = phoneModel.index(2, 0);
        QString phoneNumber3 = phoneModel.data(secondIndex, role).toString();

        QCOMPARE(phoneModel.rowCount(), 3);
        QCOMPARE(phoneNumber3, u"+34 691 86 06 75"_s);

        // Deleting a phone number
        phonenumbers.remove(1);
        addressee.setPhoneNumbers(phonenumbers);
        phoneModel.loadContact(addressee);
        QModelIndex firstIndex = phoneModel.index(1, 0);
        QString phoneNumber2 = phoneModel.data(firstIndex, role).toString();

        QCOMPARE(phoneModel.rowCount(), 2);
        QCOMPARE(phoneNumber1, u"+49 721 605605-0"_s);
        QCOMPARE(phoneNumber2, u"+34 691 86 06 75"_s);

        // Modifying a phone number
        phonenumbers.replace(0, u"+44 203 514 2299"_s);
        addressee.setPhoneNumbers(phonenumbers);
        phoneModel.loadContact(addressee);
        phoneNumber1 = phoneModel.data(zeroIndex, role).toString();

        QCOMPARE(phoneNumber1, u"+44 203 514 2299"_s);
    }
};

QTEST_MAIN(PhoneModelTest)
#include "phonemodeltest.moc"
