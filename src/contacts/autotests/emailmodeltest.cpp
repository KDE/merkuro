// SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: BSD-2-Clause

#include "../emailmodel.h"
#include <KContacts/Email>
#include <KLocalizedString>
#include <QObject>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class EmailModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KContacts::Addressee addressee;
        KContacts::Email::List emails;
        emails.append(KContacts::Email(u"carl@carlschwan.eu"_s));
        emails.append(KContacts::Email(u"carl1@carlschwan.eu"_s));
        KContacts::Email email(u"carl2@carlschwan.eu"_s);
        email.setPreferred(true);
        email.setType(KContacts::Email::Home);
        emails.append(email);
        addressee.setEmailList(emails);
        EmailModel emailModel;
        emailModel.loadContact(addressee);

        QCOMPARE(emailModel.rowCount(), 3);
        QCOMPARE(emailModel.data(emailModel.index(2, 0), Qt::DisplayRole).toString(), u"carl2@carlschwan.eu"_s);
        QCOMPARE(emailModel.data(emailModel.index(2, 0), EmailModel::DefaultRole).toBool(), true);
        QCOMPARE(emailModel.data(emailModel.index(2, 0), EmailModel::TypeRole).toString(), i18n("Home:"));
    }
};

QTEST_MAIN(EmailModelTest)
#include "emailmodeltest.moc"
