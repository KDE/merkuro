// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../contactgroupmodel.h"

#include <QTest>

using namespace Qt::Literals::StringLiterals;

class ContactGroupModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void loadsAndEditsMembers()
    {
        KContacts::ContactGroup group(u"KDE Friends"_s);
        group.append(KContacts::ContactGroup::Data(u"Ada Lovelace"_s, u"ada@example.org"_s));
        group.append(KContacts::ContactGroup::Data(u"Grace Hopper"_s, u"grace@example.org"_s));

        ContactGroupModel model(true);
        model.loadContactGroup(group);

        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.data(model.index(0, 0), ContactGroupModel::DisplayNameRole).toString(), u"Ada Lovelace"_s);
        QCOMPARE(model.data(model.index(0, 0), ContactGroupModel::EmailRole).toString(), u"ada@example.org"_s);
        QVERIFY(model.flags(model.index(0, 0)).testFlag(Qt::ItemIsEditable));

        QVERIFY(model.setData(model.index(0, 0), u"Ada Byron Lovelace"_s, Qt::EditRole));
        QVERIFY(model.setData(model.index(0, 1), u"ada@kde.org"_s, Qt::EditRole));
        QCOMPARE(model.data(model.index(0, 0), Qt::DisplayRole).toString(), u"Ada Byron Lovelace"_s);
        QCOMPARE(model.data(model.index(0, 0), ContactGroupModel::EmailRole).toString(), u"ada@kde.org"_s);
    }

    void addsRemovesAndStoresMembers()
    {
        ContactGroupModel model(true);
        model.addContactFromData(u"Ada Lovelace"_s, u"ada@example.org"_s);
        model.addContactFromData(u"Grace Hopper"_s, u"grace@example.org"_s);
        QCOMPARE(model.rowCount(), 2);

        model.removeContact(0);
        QCOMPARE(model.rowCount(), 1);

        KContacts::ContactGroup stored;
        QVERIFY(model.storeContactGroup(stored));
        QCOMPARE(stored.dataCount(), 1);
        QCOMPARE(stored.data(0).name(), u"Grace Hopper"_s);
        QCOMPARE(stored.data(0).email(), u"grace@example.org"_s);
    }

    void rejectsMembersWithoutEmail()
    {
        ContactGroupModel model(true);
        model.addContactFromData(u"Missing Email"_s, {});

        KContacts::ContactGroup stored;
        QVERIFY(!model.storeContactGroup(stored));
        QVERIFY(model.lastErrorMessage().contains(u"Missing Email"_s));
    }
};

QTEST_MAIN(ContactGroupModelTest)

#include "contactgroupmodeltest.moc"
