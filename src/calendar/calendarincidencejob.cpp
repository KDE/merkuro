// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "calendarincidencejob.h"
#include "calendarmanager.h"
#include "incidencewrapper.h"

#include <Akonadi/ItemMoveJob>
#include <KLocalizedString>
#include <QSet>
#include <utility>

CalendarIncidenceJob::CalendarIncidenceJob(CalendarManager *manager, QObject *parent)
    : KJob(parent)
    , m_manager(manager)
    , m_changer(manager ? manager->incidenceChanger() : nullptr)
{
    if (m_manager) {
        connect(m_manager, &QObject::destroyed, this, [this] {
            complete(i18n("The calendar is no longer available."));
        });
    }
    if (m_changer) {
        connect(m_changer, &Akonadi::IncidenceChanger::createFinished, this, [this](int id, const Akonadi::Item &item, auto result, const QString &error) {
            changeFinished(id, ChangeType::Create, item, result, error);
        });
        connect(m_changer, &Akonadi::IncidenceChanger::modifyFinished, this, [this](int id, const Akonadi::Item &item, auto result, const QString &error) {
            changeFinished(id, ChangeType::Modify, item, result, error);
        });
        connect(m_changer, &Akonadi::IncidenceChanger::deleteFinished, this, [this](int id, const auto &, auto result, const QString &error) {
            changeFinished(id, ChangeType::Delete, {}, result, error);
        });
        connect(m_changer, &QObject::destroyed, this, [this] {
            complete(i18n("The calendar is no longer available."));
        });
    }
}

bool CalendarIncidenceJob::failPreparation(const QString &error)
{
    m_failure = error;
    setError(UserDefinedError);
    setErrorText(error);
    return false;
}

Akonadi::Item::List CalendarIncidenceJob::seriesItems(const Akonadi::Item &item) const
{
    Akonadi::Item::List items{item};
    const auto incidence = item.payload<KCalendarCore::Incidence::Ptr>();
    if (incidence->recurs() && !incidence->hasRecurrenceId()) {
        for (const auto &exception : m_manager->calendar()->instances(incidence)) {
            const auto exceptionItem = m_manager->incidenceItem(exception);
            if (exceptionItem.isValid() && exceptionItem.id() != item.id()) {
                items.append(exceptionItem);
            }
        }
    }
    return items;
}

Akonadi::Item::List CalendarIncidenceJob::relatedItems(const Akonadi::Item &item, bool includeParents) const
{
    Akonadi::Item::List pending{item};
    Akonadi::Item::List result;
    QSet<Akonadi::Item::Id> visited;
    for (qsizetype i = 0; i < pending.size(); ++i) {
        const auto current = pending.at(i);
        if (!current.isValid() || visited.contains(current.id()) || !current.hasPayload<KCalendarCore::Incidence::Ptr>()) {
            continue;
        }
        visited.insert(current.id());
        result.append(current);
        const auto incidence = current.payload<KCalendarCore::Incidence::Ptr>();
        pending.append(seriesItems(current));
        for (const auto &child : m_manager->childIncidences(incidence->uid())) {
            pending.append(m_manager->incidenceItem(child));
        }
        if (includeParents && !incidence->relatedTo().isEmpty()) {
            pending.append(m_manager->incidenceItem(incidence->relatedTo()));
        }
    }
    return result;
}

bool CalendarIncidenceJob::validateMove()
{
    if (!m_destination.isValid() || !(m_destination.rights() & Akonadi::Collection::CanCreateItem)) {
        return failPreparation(i18n("The selected calendar is read-only or unavailable."));
    }
    for (const auto &item : std::as_const(m_itemsToMove)) {
        if (!(m_manager->getCollection(item.parentCollection().id()).rights() & Akonadi::Collection::CanDeleteItem)
            || !m_destination.contentMimeTypes().contains(item.mimeType())) {
            return failPreparation(i18n("The incidence and its related tasks cannot be moved to the selected calendar."));
        }
    }
    return true;
}

bool CalendarIncidenceJob::prepareSave(IncidenceWrapper *wrapper, bool editMode)
{
    if (!m_manager || !m_manager->calendar() || !m_changer || !wrapper || !wrapper->incidencePtr()) {
        return failPreparation(i18n("The incidence is not available."));
    }
    m_destination = m_manager->getCollection(wrapper->collectionId());
    if (!m_destination.isValid()) {
        return failPreparation(i18n("No calendar selected."));
    }
    if (!m_destination.contentMimeTypes().contains(wrapper->incidencePtr()->mimeType())) {
        return failPreparation(i18n("The selected calendar cannot store this incidence."));
    }
    if (editMode) {
        const auto storedItem = m_manager->incidenceItem(wrapper->incidencePtr());
        auto item = wrapper->incidenceItem();
        if (!storedItem.isValid() || !item.isValid() || item.id() != storedItem.id() || !wrapper->originalIncidencePtr()) {
            if (item.isValid()) {
                wrapper->recordRemoval();
            }
            return failPreparation(i18n("The incidence is no longer available."));
        }
        wrapper->recordExternalChange(storedItem);
        if (wrapper->hasExternalChanges()) {
            return failPreparation(wrapper->incidenceDeleted()
                                       ? i18n("The incidence was deleted. Your unsaved changes have been kept.")
                                       : i18n("The incidence changed outside this editor. Reload it before saving. Your unsaved changes have been kept."));
        }
        if (!(m_manager->getCollection(item.parentCollection().id()).rights() & Akonadi::Collection::CanChangeItem)) {
            return failPreparation(i18n("The incidence is read-only."));
        }
        if (item.parentCollection().id() != m_destination.id()) {
            m_itemsToMove = relatedItems(item, true);
            if (!validateMove()) {
                return false;
            }
        }
        item.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(wrapper->incidencePtr()->clone()));
        m_modifications.append({item, KCalendarCore::Incidence::Ptr(wrapper->originalIncidencePtr()->clone())});
    } else {
        if (!(m_destination.rights() & Akonadi::Collection::CanCreateItem)) {
            return failPreparation(i18n("The selected calendar is read-only."));
        }
        m_incidenceToCreate = KCalendarCore::Incidence::Ptr(wrapper->incidencePtr()->clone());
    }
    m_wrapper = wrapper;
    return true;
}

bool CalendarIncidenceJob::prepareDateChange(IncidenceWrapper *wrapper, int startOffset, int endOffset, int occurrences, const QDateTime &occurrenceDate)
{
    if (!prepareSave(wrapper, true)) {
        return false;
    }
    auto incidence = m_modifications.first().item.payload<KCalendarCore::Incidence::Ptr>();
    if (incidence->recurs() && occurrences != IncidenceWrapper::AllOccurrences) {
        if ((occurrences != IncidenceWrapper::SelectedOccurrence && occurrences != IncidenceWrapper::FutureOccurrences) || !occurrenceDate.isValid()) {
            return failPreparation(i18n("No occurrence selected."));
        }
        incidence = KCalendarCore::Calendar::createException(incidence,
                                                             occurrenceDate.toTimeZone(incidence->dtStart().timeZone()),
                                                             occurrences == IncidenceWrapper::FutureOccurrences);
        if (!incidence) {
            return failPreparation(i18n("Unable to create the occurrence exception."));
        }
        m_modifications.clear();
        m_itemsToMove.clear();
        m_incidenceToCreate = incidence;
        // The exception is a separate item; the source wrapper still describes the series.
        m_wrapper = nullptr;
    }
    if (incidence->type() == KCalendarCore::Incidence::TypeTodo) {
        const auto todo = incidence.staticCast<KCalendarCore::Todo>();
        if (todo->hasDueDate()) {
            todo->setDtDue(todo->dtDue().addMSecs(startOffset));
            if (todo->hasStartDate() && todo->dtStart() > todo->dtDue()) {
                todo->setDtStart(todo->dtDue());
            }
        } else if (todo->hasStartDate()) {
            todo->setDtStart(todo->dtStart().addMSecs(startOffset));
        }
    } else {
        incidence->setDtStart(incidence->dtStart().addMSecs(startOffset));
        if (incidence->type() == KCalendarCore::Incidence::TypeEvent) {
            const auto event = incidence.staticCast<KCalendarCore::Event>();
            event->setDtEnd(event->dtEnd().addMSecs(endOffset));
        }
    }
    if (m_incidenceToCreate && !(m_destination.rights() & Akonadi::Collection::CanCreateItem)) {
        return failPreparation(i18n("The selected calendar is read-only."));
    }
    return true;
}

bool CalendarIncidenceJob::prepareMove(const Akonadi::Item &item, const Akonadi::Collection &destination)
{
    if (!m_manager || !m_manager->calendar() || !m_changer || !item.isValid() || !item.hasPayload<KCalendarCore::Incidence::Ptr>()) {
        return failPreparation(i18n("The incidence is not available."));
    }
    m_destination = destination;
    m_itemsToMove = relatedItems(item, true);
    m_itemsToMove.removeIf([&destination](const auto &related) {
        return related.parentCollection().id() == destination.id();
    });
    return m_itemsToMove.isEmpty() || validateMove();
}

bool CalendarIncidenceJob::prepareDelete(const KCalendarCore::Incidence::Ptr &incidence, bool deleteChildren)
{
    if (!m_manager || !m_manager->calendar() || !m_changer || !incidence) {
        return failPreparation(i18n("The incidence is not available."));
    }
    const auto item = m_manager->incidenceItem(incidence);
    if (!item.isValid()) {
        return failPreparation(i18n("The incidence is no longer available."));
    }
    m_deletions = deleteChildren ? relatedItems(item, false) : seriesItems(item);
    if (!deleteChildren) {
        QSet<Akonadi::Item::Id> visited;
        for (const auto &child : m_manager->childIncidences(incidence->uid())) {
            auto instances = m_manager->calendar()->instances(child);
            instances.append(child);
            for (const auto &instance : std::as_const(instances)) {
                auto childItem = m_manager->incidenceItem(instance);
                if (!childItem.isValid() || visited.contains(childItem.id())) {
                    continue;
                }
                visited.insert(childItem.id());
                const KCalendarCore::Incidence::Ptr original(instance->clone());
                const KCalendarCore::Incidence::Ptr draft(instance->clone());
                draft->setRelatedTo({});
                childItem.setPayload<KCalendarCore::Incidence::Ptr>(draft);
                m_modifications.append({childItem, original});
            }
        }
    }
    return true;
}

void CalendarIncidenceJob::start()
{
    if (m_started || isFinished()) {
        return;
    }
    m_started = true;
    QMetaObject::invokeMethod(this, &CalendarIncidenceJob::doStart, Qt::QueuedConnection);
}

void CalendarIncidenceJob::doStart()
{
    if (!m_failure.isEmpty() || !m_manager || !m_changer) {
        complete(m_failure.isEmpty() ? i18n("The calendar is no longer available.") : m_failure);
        return;
    }
    m_submitting = true;
    const bool atomic = m_modifications.size() + !m_deletions.isEmpty() + bool(m_incidenceToCreate) > 1;
    if (atomic) {
        m_changer->startAtomicOperation(i18n("Change incidence"));
    }
    const auto track = [this](int id, ChangeType type) {
        if (id < 0) {
            m_failure = i18n("The incidence could not be changed.");
        } else {
            m_changes.insert(id, type);
        }
    };
    if (m_incidenceToCreate) {
        track(createIncidence(m_incidenceToCreate, m_destination), ChangeType::Create);
    }
    for (const auto &modification : std::as_const(m_modifications)) {
        track(modifyIncidence(modification.item, modification.original), ChangeType::Modify);
    }
    if (!m_deletions.isEmpty()) {
        track(deleteIncidences(m_deletions), ChangeType::Delete);
    }
    if (atomic) {
        m_changer->endAtomicOperation();
    }
    m_submitting = false;
    finishChanges();
}

int CalendarIncidenceJob::createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection)
{
    return m_changer->createIncidence(incidence, collection);
}

int CalendarIncidenceJob::modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original)
{
    auto changedItem = item;
    // Change the payload, not the resource-managed remote ID, which may be stale after a move.
    changedItem.setRemoteId(QString());
    // TODO: Use FailOnConflict once available to also catch revision changes after the cache check.
    return m_changer->modifyIncidence(changedItem, original);
}

int CalendarIncidenceJob::deleteIncidences(const Akonadi::Item::List &items)
{
    return m_changer->deleteIncidences(items);
}

KJob *CalendarIncidenceJob::moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &collection)
{
    return new Akonadi::ItemMoveJob(items, collection, this);
}

void CalendarIncidenceJob::changeFinished(int id,
                                          ChangeType type,
                                          const Akonadi::Item &item,
                                          Akonadi::IncidenceChanger::ResultCode result,
                                          const QString &error)
{
    const auto it = m_changes.find(id);
    if (isFinished() || it == m_changes.end() || it.value() != type) {
        return;
    }
    m_changes.erase(it);
    if (result != Akonadi::IncidenceChanger::ResultCodeSuccess) {
        if (m_failure.isEmpty()) {
            m_failure = error.isEmpty() ? i18n("The incidence could not be changed.") : error;
        }
    } else if (type != ChangeType::Delete) {
        m_savedItem = item;
        // Keep the persisted revision for retrying after a failed move.
        updateWrapper(item);
        for (auto &related : m_itemsToMove) {
            if (related.id() == item.id()) {
                related = item;
            }
        }
    }
    finishChanges();
}

void CalendarIncidenceJob::updateWrapper(const Akonadi::Item &item)
{
    if (m_wrapper && item.hasPayload<KCalendarCore::Incidence::Ptr>()) {
        auto snapshot = item;
        snapshot.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(item.payload<KCalendarCore::Incidence::Ptr>()->clone()));
        m_wrapper->setIncidenceItem(snapshot);
    }
}

void CalendarIncidenceJob::finishChanges()
{
    if (m_submitting || !m_changes.isEmpty() || isFinished()) {
        return;
    }
    if (!m_failure.isEmpty()) {
        complete(m_failure);
        return;
    }
    if (m_itemsToMove.isEmpty()) {
        complete();
        return;
    }
    auto job = moveItems(std::exchange(m_itemsToMove, {}), m_destination);
    if (!job) {
        complete(i18n("The incidence could not be moved."));
        return;
    }
    connect(job, &KJob::result, this, [this](KJob *move) {
        if (move->error()) {
            complete(m_savedItem.isValid() ? i18n("The incidence was saved, but could not be moved: %1", move->errorString())
                                           : i18n("The incidence could not be moved: %1", move->errorString()));
            return;
        }
        if (m_savedItem.isValid()) {
            m_savedItem.setParentCollection(m_destination);
            updateWrapper(m_savedItem);
        }
        complete();
    });
}

void CalendarIncidenceJob::complete(const QString &error)
{
    if (isFinished()) {
        return;
    }
    if (!error.isEmpty()) {
        setError(UserDefinedError);
        setErrorText(error);
    }
    emitResult();
}

#include "moc_calendarincidencejob.cpp"
