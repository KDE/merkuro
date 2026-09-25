// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactactivitymodel.h"

#include <Akonadi/MessageFlags>
#include <KCalendarCore/Event>
#include <QTest>

using namespace Qt::Literals::StringLiterals;

class ContactActivityModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void showsFiveMostRecentPastEvents()
    {
        ContactActivityModel model;
        model.setKind(ContactActivityModel::Events);

        Akonadi::Item::List items;
        const auto now = QDateTime::currentDateTime();
        for (int daysAgo : {4, 7, 2, 6, 1, -1, 3, 5}) {
            KCalendarCore::Event::Ptr event(new KCalendarCore::Event);
            event->setSummary(QString::number(daysAgo));
            event->setOrganizer(KCalendarCore::Person(u"Ada Lovelace"_s, u"ada@example.org"_s));
            event->setDtStart(now.addDays(-daysAgo));
            Akonadi::Item item(KCalendarCore::Event::eventMimeType());
            item.setPayload<KCalendarCore::Incidence::Ptr>(event);
            items.append(item);
        }

        model.updateItems(items);
        QCOMPARE(model.rowCount(), 5);
        QCOMPARE(model.count(), 5);
        QCOMPARE(model.property("count").toInt(), 5);
        QCOMPARE(model.index(0, 0).data(ContactActivityModel::PersonRole).toString(), u"Ada Lovelace"_s);
        QCOMPARE(model.index(0, 0).data(ContactActivityModel::EmailRole).toString(), u"ada@example.org"_s);
        QCOMPARE(model.index(0, 0).data(ContactActivityModel::UnreadRole).toBool(), false);
        for (int row = 0; row < 5; ++row) {
            QCOMPARE(model.index(row, 0).data(ContactActivityModel::TitleRole).toString(), QString::number(row + 1));
        }
    }

    void unreadRoleUsesMessageFlags()
    {
        ContactActivityModel model;
        Akonadi::Item unread(u"message/rfc822"_s);
        model.updateItems({unread});
        QCOMPARE(model.index(0, 0).data(ContactActivityModel::UnreadRole).toBool(), true);

        Akonadi::Item read(u"message/rfc822"_s);
        read.setFlag(Akonadi::MessageFlags::Seen);
        model.updateItems({read});
        QCOMPARE(model.index(0, 0).data(ContactActivityModel::UnreadRole).toBool(), false);
    }
};

QTEST_GUILESS_MAIN(ContactActivityModelTest)
#include "contactactivitymodeltest.moc"
