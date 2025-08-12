// SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: BSD-2-Clause

#include "../imppmodel.h"
#include <KContacts/Impp>
#include <KLocalizedString>
#include <QObject>
#include <QTest>
using namespace Qt::Literals::StringLiterals;
class ImppModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KContacts::Addressee addressee;
        KContacts::Impp::List impps;
        impps.append(KContacts::Impp(QUrl{u"matrix:@carl:kde.org"_s}));
        impps.append(KContacts::Impp(QUrl{u"matrix:@carl2:kde.org"_s}));
        addressee.setImppList(impps);
        ImppModel imppModel;
        imppModel.loadContact(addressee);

        QCOMPARE(imppModel.rowCount(), 2);
        QCOMPARE(imppModel.data(imppModel.index(1, 0), ImppModel::UrlRole).toString(), u"matrix:@carl2:kde.org"_s);
    }
};

QTEST_MAIN(ImppModelTest)
#include "imppmodeltest.moc"
