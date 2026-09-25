// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactlistproxymodel.h"

#include <Akonadi/EntityTreeModel>
#include <KContacts/Addressee>
#include <KLocalizedString>
#include <QStandardItemModel>
#include <QTest>

using namespace Qt::Literals::StringLiterals;

class ContactListProxyModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        KLocalizedString::setApplicationDomain("merkuro");
    }

    void filtersBirthdayContactsAndPreservesSearch()
    {
        QStandardItemModel source;
        for (const auto &[id, name] : {std::pair{Akonadi::Item::Id(1), u"Ada"_s}, std::pair{Akonadi::Item::Id(2), u"Grace"_s}}) {
            auto item = new QStandardItem(name);
            item->setData(QVariant::fromValue(Akonadi::Item(id)), Akonadi::EntityTreeModel::ItemRole);
            source.appendRow(item);
        }

        ContactListProxyModel model;
        model.setSourceModel(&source);
        QCOMPARE(model.rowCount(), 2);

        model.setBirthdays({{2, QDate(1970, 6, 15)}});
        model.setBirthdaysOnly(true);
        QCOMPARE(model.rowCount(), 1);
        QCOMPARE(model.index(0, 0).data().toString(), u"Grace"_s);

        model.setFilterFixedString(u"Ada"_s);
        QCOMPARE(model.rowCount(), 0);
        model.setFilterFixedString(u"Grace"_s);
        QCOMPARE(model.rowCount(), 1);

        model.setBirthdays({{1, QDate(1970, 6, 15)}});
        QCOMPARE(model.rowCount(), 0);

        model.setBirthdaysOnly(false);
        model.setFilterFixedString({});
        QCOMPARE(model.rowCount(), 2);
    }

    void sortsByNextBirthdayAndExposesSections()
    {
        QStandardItemModel source;
        for (const auto &[id, name] : {std::pair{Akonadi::Item::Id(1), u"Ada"_s}, std::pair{Akonadi::Item::Id(2), u"Grace"_s}}) {
            auto item = new QStandardItem(name);
            item->setData(QVariant::fromValue(Akonadi::Item(id)), Akonadi::EntityTreeModel::ItemRole);
            source.appendRow(item);
        }

        const auto today = QDate::currentDate();
        ContactListProxyModel model;
        model.setSourceModel(&source);
        model.setBirthdays({{1, today.addDays(20).addYears(-40)}, {2, today.addDays(2).addYears(-30)}});
        model.setBirthdaysOnly(true);

        QCOMPARE(model.index(0, 0).data(Qt::DisplayRole).toString(), u"Grace"_s);
        QCOMPARE(model.index(0, 0).data(ContactListProxyModel::BirthdayDateRole).toDate(), today.addDays(2));
        QCOMPARE(model.index(0, 0).data(ContactListProxyModel::BirthdayAgeRole).toInt(), 30);
        QCOMPARE(model.index(1, 0).data(Qt::DisplayRole).toString(), u"Ada"_s);
        QVERIFY(!model.index(0, 0).data(ContactListProxyModel::BirthdaySectionRole).toString().isEmpty());

        model.setBirthdays({{1, today}, {2, today.addDays(2).addYears(-30)}});
        QCOMPARE(model.index(0, 0).data(Qt::DisplayRole).toString(), u"Ada"_s);
        QCOMPARE(model.index(0, 0).data(ContactListProxyModel::BirthdaySectionRole).toString(), u"Today"_s);
    }

    void fullNameUsesContactNameInsteadOfDisplayRole()
    {
        QStandardItemModel source;
        auto sourceItem = new QStandardItem(u"email@example.org"_s);
        Akonadi::Item item(1);
        item.setMimeType(KContacts::Addressee::mimeType());
        KContacts::Addressee addressee;
        addressee.setGivenName(u"Ada"_s);
        addressee.setFamilyName(u"Lovelace"_s);
        item.setPayload(addressee);
        sourceItem->setData(QVariant::fromValue(item), Akonadi::EntityTreeModel::ItemRole);
        source.appendRow(sourceItem);

        ContactListProxyModel model;
        model.setSourceModel(&source);

        QCOMPARE(model.roleNames().value(ContactListProxyModel::FullNameRole), "fullName");
        QCOMPARE(model.index(0, 0).data(ContactListProxyModel::FullNameRole).toString(), u"Ada Lovelace"_s);
        QCOMPARE(model.index(0, 0).data(Qt::DisplayRole).toString(), u"email@example.org"_s);
    }

    void nextBirthdayWrapsAroundYear()
    {
        QCOMPARE(ContactListProxyModel::nextBirthday(QDate(1980, 1, 2), QDate(2026, 12, 31)), QDate(2027, 1, 2));
        QCOMPARE(ContactListProxyModel::nextBirthday(QDate(1980, 12, 31), QDate(2026, 12, 31)), QDate(2026, 12, 31));
    }
};

QTEST_GUILESS_MAIN(ContactListProxyModelTest)
#include "contactlistproxymodeltest.moc"
