// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "birthdaycalendar.h"

#include <Akonadi/AgentManager>
#include <Akonadi/CalendarUtils>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Monitor>
#include <KCalendarCore/Event>
#include <KJob>

using namespace Qt::Literals::StringLiterals;

BirthdayCalendar::BirthdayCalendar(QObject *parent)
    : QObject(parent)
    , m_monitor(new Akonadi::Monitor(this))
{
    m_monitor->itemFetchScope().fetchFullPayload(true);
    connect(m_monitor, &Akonadi::Monitor::itemAdded, this, [this](const Akonadi::Item &item, const Akonadi::Collection &collection) {
        if (collection.id() == m_collection.id()) {
            m_events.insert(item.id(), item);
            Q_EMIT birthdaysChanged();
        }
    });
    connect(m_monitor, &Akonadi::Monitor::itemChanged, this, [this](const Akonadi::Item &item) {
        if (m_events.contains(item.id())) {
            m_events.insert(item.id(), item);
            Q_EMIT birthdaysChanged();
        }
    });
    connect(m_monitor, &Akonadi::Monitor::itemRemoved, this, [this](const Akonadi::Item &item) {
        if (m_events.remove(item.id())) {
            Q_EMIT birthdaysChanged();
        }
    });
    connect(m_monitor, &Akonadi::Monitor::collectionRemoved, this, [this](const Akonadi::Collection &collection) {
        if (collection.id() == m_collection.id()) {
            m_monitor->setCollectionMonitored(m_collection, false);
            m_collection = {};
            m_events.clear();
            Q_EMIT birthdaysChanged();
            findCollection();
        }
    });
    connect(Akonadi::AgentManager::self(), &Akonadi::AgentManager::instanceAdded, this, [this]() {
        findCollection();
    });
    findCollection();
}

QHash<Akonadi::Item::Id, QDate> BirthdayCalendar::birthdays() const
{
    QHash<Akonadi::Item::Id, QDate> dates;
    for (const auto &event : m_events) {
        const auto id = contactId(event, m_collection);
        if (id > 0) {
            dates.insert(id, birthdayDate(event, m_collection));
        }
    }
    return dates;
}

Akonadi::Item::Id BirthdayCalendar::contactId(const Akonadi::Item &event, const Akonadi::Collection &collection)
{
    if (collection.remoteId() != u"akonadi_birthdays_resource"_s || !event.remoteId().startsWith(u'b')) {
        return -1;
    }

    bool validId = false;
    const auto contactId = event.remoteId().sliced(1).toLongLong(&validId);
    if (!validId || contactId <= 0) {
        return -1;
    }

    const auto incidence = Akonadi::CalendarUtils::incidence(event);
    return incidence && incidence->customProperty("KABC"_ba, "BIRTHDAY"_ba) == u"YES"_s ? contactId : -1;
}

QDate BirthdayCalendar::birthdayDate(const Akonadi::Item &event, const Akonadi::Collection &collection)
{
    if (contactId(event, collection) <= 0) {
        return {};
    }
    return Akonadi::CalendarUtils::incidence(event)->dtStart().date();
}

void BirthdayCalendar::findCollection()
{
    auto job = new Akonadi::CollectionFetchJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive, this);
    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            return;
        }
        const auto collections = job->collections();
        for (const auto &collection : collections) {
            if (collection.remoteId() != u"akonadi_birthdays_resource"_s || collection.id() == m_collection.id()) {
                continue;
            }
            if (m_collection.isValid()) {
                m_monitor->setCollectionMonitored(m_collection, false);
            }
            m_collection = collection;
            m_events.clear();
            Q_EMIT birthdaysChanged();
            m_monitor->setCollectionMonitored(m_collection);
            fetchEvents();
            return;
        }
    });
}

void BirthdayCalendar::fetchEvents()
{
    const auto collectionId = m_collection.id();
    auto job = new Akonadi::ItemFetchJob(m_collection, this);
    job->fetchScope().fetchFullPayload(true);
    connect(job, &KJob::result, this, [this, job, collectionId]() {
        if (job->error() || collectionId != m_collection.id()) {
            return;
        }
        m_events.clear();
        const auto events = job->items();
        for (const auto &event : events) {
            m_events.insert(event.id(), event);
        }
        Q_EMIT birthdaysChanged();
    });
}

#include "moc_birthdaycalendar.cpp"
