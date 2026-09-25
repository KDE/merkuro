// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/Collection>
#include <Akonadi/Item>
#include <QDate>
#include <QHash>
#include <QObject>

#include "merkuro_contact_export.h"

namespace Akonadi
{
class Monitor;
}

class MERKURO_CONTACT_EXPORT BirthdayCalendar : public QObject
{
    Q_OBJECT

public:
    explicit BirthdayCalendar(QObject *parent = nullptr);

    [[nodiscard]] QHash<Akonadi::Item::Id, QDate> birthdays() const;
    [[nodiscard]] static Akonadi::Item::Id contactId(const Akonadi::Item &event, const Akonadi::Collection &collection);
    [[nodiscard]] static QDate birthdayDate(const Akonadi::Item &event, const Akonadi::Collection &collection);

Q_SIGNALS:
    void birthdaysChanged();

private:
    void findCollection();
    void fetchEvents();

    Akonadi::Monitor *const m_monitor;
    Akonadi::Collection m_collection;
    QHash<Akonadi::Item::Id, Akonadi::Item> m_events;
};
