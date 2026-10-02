// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/IncidenceChanger>
#include <KJob>
#include <QHash>
#include <QPointer>
#include <qqmlintegration.h>

class CalendarManager;
class IncidenceWrapper;

// One user operation, including its changes and any subsequent collection move.
// The shared IncidenceChanger remains responsible for persistence and history.
class CalendarIncidenceJob : public KJob
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Calendar operations are created by CalendarManager")

public:
    explicit CalendarIncidenceJob(CalendarManager *manager, QObject *parent = nullptr);
    bool prepareSave(IncidenceWrapper *wrapper, bool editMode);
    bool prepareDateChange(IncidenceWrapper *wrapper, int startOffset, int endOffset, int occurrences, const QDateTime &occurrenceDate);
    bool prepareMove(const Akonadi::Item &item, const Akonadi::Collection &destination);
    bool prepareDelete(const KCalendarCore::Incidence::Ptr &incidence, bool deleteChildren);
    void start() override;

protected:
    // Tests can control submission, completion order, and failures without server jobs.
    virtual int createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection);
    virtual int modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original);
    virtual int deleteIncidences(const Akonadi::Item::List &items);
    virtual KJob *moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &collection);

private:
    struct Modification {
        Akonadi::Item item;
        KCalendarCore::Incidence::Ptr original;
    };
    enum class ChangeType {
        Create,
        Modify,
        Delete
    };
    bool failPreparation(const QString &error);
    Akonadi::Item::List seriesItems(const Akonadi::Item &item) const;
    Akonadi::Item::List relatedItems(const Akonadi::Item &item, bool includeParents) const;
    bool validateMove();
    void doStart();
    void changeFinished(int id, ChangeType type, const Akonadi::Item &item, Akonadi::IncidenceChanger::ResultCode result, const QString &error);
    void finishChanges();
    void complete(const QString &error = {});
    void updateWrapper(const Akonadi::Item &item);

    QPointer<CalendarManager> m_manager;
    QPointer<Akonadi::IncidenceChanger> m_changer;
    QPointer<IncidenceWrapper> m_wrapper;
    QList<Modification> m_modifications;
    Akonadi::Item::List m_deletions;
    Akonadi::Item::List m_itemsToMove;
    KCalendarCore::Incidence::Ptr m_incidenceToCreate;
    Akonadi::Collection m_destination;
    Akonadi::Item m_savedItem;
    QHash<int, ChangeType> m_changes;
    QString m_failure;
    bool m_started = false;
    bool m_submitting = false;
};
