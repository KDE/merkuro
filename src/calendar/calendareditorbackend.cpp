// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "calendareditorbackend.h"
#include "calendarmanager.h"
#include "incidencewrapper.h"

#include <Akonadi/ItemMoveJob>
#include <KJob>
#include <KLocalizedString>
#include <QSet>
#include <utility>

CalendarEditorBackend::CalendarEditorBackend(QObject *parent)
    : QObject(parent)
{
}

CalendarManager *CalendarEditorBackend::calendarManager() const
{
    return m_manager;
}

void CalendarEditorBackend::setCalendarManager(CalendarManager *manager)
{
    if (m_saving || m_manager == manager) {
        return;
    }
    if (m_manager) {
        disconnect(m_manager->incidenceChanger(), nullptr, this, nullptr);
        disconnect(m_manager, nullptr, this, nullptr);
    }
    m_manager = manager;
    if (m_manager && m_manager->incidenceChanger()) {
        auto changer = m_manager->incidenceChanger();
        connect(changer, &Akonadi::IncidenceChanger::createFinished, this, [this](int id, const Akonadi::Item &item, auto result, const QString &error) {
            if (!m_editMode) {
                changeFinished(id, item, result, error);
            }
        });
        connect(changer, &Akonadi::IncidenceChanger::modifyFinished, this, [this](int id, const Akonadi::Item &item, auto result, const QString &error) {
            if (m_editMode) {
                changeFinished(id, item, result, error);
            }
        });
        connect(m_manager, &QObject::destroyed, this, [this] {
            if (m_saving) {
                complete(i18n("The calendar is no longer available."));
            }
            Q_EMIT calendarManagerChanged();
        });
    }
    Q_EMIT calendarManagerChanged();
}

bool CalendarEditorBackend::saving() const
{
    return m_saving;
}

QString CalendarEditorBackend::errorMessage() const
{
    return m_errorMessage;
}

void CalendarEditorBackend::setErrorMessage(const QString &error)
{
    if (m_errorMessage != error) {
        m_errorMessage = error;
        Q_EMIT errorMessageChanged();
    }
}

Akonadi::Item::List CalendarEditorBackend::relatedItems(const Akonadi::Item &item) const
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
        for (const auto &child : m_manager->childIncidences(incidence->uid())) {
            pending.append(m_manager->incidenceItem(child));
        }
        if (!incidence->relatedTo().isEmpty()) {
            pending.append(m_manager->incidenceItem(incidence->relatedTo()));
        }
    }
    return result;
}

void CalendarEditorBackend::save(IncidenceWrapper *wrapper, bool editMode)
{
    if (m_saving) {
        return;
    }
    setErrorMessage({});
    if (!m_manager || !m_manager->calendar() || !m_manager->incidenceChanger() || !wrapper || !wrapper->incidencePtr()) {
        setErrorMessage(i18n("The incidence is not available."));
        return;
    }
    if (wrapper->summary().trimmed().isEmpty()) {
        setErrorMessage(i18n("Please enter a title."));
        return;
    }
    m_destination = m_manager->getCollection(wrapper->collectionId());
    if (!m_destination.isValid()) {
        setErrorMessage(i18n("No calendar selected."));
        return;
    }
    if (!m_destination.contentMimeTypes().contains(wrapper->incidencePtr()->mimeType())) {
        setErrorMessage(i18n("The selected calendar cannot store this incidence."));
        return;
    }

    Akonadi::Item item;
    m_itemsToMove.clear();
    if (editMode) {
        const auto storedItem = m_manager->incidenceItem(wrapper->incidencePtr());
        item = wrapper->incidenceItem();
        if (!storedItem.isValid() || !item.isValid() || item.id() != storedItem.id() || !wrapper->originalIncidencePtr()) {
            if (item.isValid()) {
                wrapper->recordRemoval();
            }
            setErrorMessage(i18n("The incidence is no longer available."));
            return;
        }
        wrapper->recordExternalChange(storedItem);
        if (wrapper->hasExternalChanges()) {
            setErrorMessage(wrapper->incidenceDeleted()
                                ? i18n("The incidence was deleted. Your unsaved changes have been kept.")
                                : i18n("The incidence changed outside this editor. Reload it before saving. Your unsaved changes have been kept."));
            return;
        }
        const auto source = m_manager->getCollection(item.parentCollection().id());
        if (!(source.rights() & Akonadi::Collection::CanChangeItem)) {
            setErrorMessage(i18n("The incidence is read-only."));
            return;
        }
        if (item.parentCollection().id() != m_destination.id()) {
            // Preserve the existing behavior of moving related tasks together.
            m_itemsToMove = relatedItems(item);
            for (const auto &related : std::as_const(m_itemsToMove)) {
                if (!(m_manager->getCollection(related.parentCollection().id()).rights() & Akonadi::Collection::CanDeleteItem)
                    || !m_destination.contentMimeTypes().contains(related.mimeType())) {
                    setErrorMessage(i18n("The incidence and its related tasks cannot be moved to the selected calendar."));
                    return;
                }
            }
        }
    }
    if ((!editMode || !m_itemsToMove.isEmpty()) && !(m_destination.rights() & Akonadi::Collection::CanCreateItem)) {
        setErrorMessage(i18n("The selected calendar is read-only."));
        return;
    }

    m_wrapper = wrapper;
    m_editMode = editMode;
    m_saving = true;
    Q_EMIT savingChanged();
    const KCalendarCore::Incidence::Ptr snapshot(wrapper->incidencePtr()->clone());
    if (editMode) {
        item.setPayload<KCalendarCore::Incidence::Ptr>(snapshot);
        m_changeId = modifyIncidence(item, KCalendarCore::Incidence::Ptr(wrapper->originalIncidencePtr()->clone()));
    } else {
        m_changeId = createIncidence(snapshot, m_destination);
    }
    if (m_changeId < 0) {
        complete(i18n("The incidence could not be saved."));
    }
}

void CalendarEditorBackend::reload(IncidenceWrapper *wrapper)
{
    if (m_saving || !wrapper) {
        return;
    }
    if (wrapper->reloadLatest()) {
        setErrorMessage({});
    } else {
        setErrorMessage(i18n("The incidence is no longer available. Your unsaved changes have been kept."));
    }
}

int CalendarEditorBackend::createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection)
{
    return m_manager->incidenceChanger()->createIncidence(incidence, collection);
}

int CalendarEditorBackend::modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original)
{
    // TODO: Use FailOnConflict once available to also catch revision changes after the cache check.
    return m_manager->incidenceChanger()->modifyIncidence(item, original);
}

KJob *CalendarEditorBackend::moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &collection)
{
    return new Akonadi::ItemMoveJob(items, collection, this);
}

void CalendarEditorBackend::changeFinished(int changeId, const Akonadi::Item &item, Akonadi::IncidenceChanger::ResultCode result, const QString &error)
{
    if (!m_saving || changeId != m_changeId) {
        return;
    }
    m_changeId = -1;
    if (result != Akonadi::IncidenceChanger::ResultCodeSuccess) {
        complete(error.isEmpty() ? i18n("The incidence could not be saved.") : error);
        return;
    }
    // Keep the persisted revision/original payload for retrying after a failed move.
    if (m_wrapper) {
        auto draftItem = item;
        draftItem.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(item.payload<KCalendarCore::Incidence::Ptr>()->clone()));
        m_wrapper->setIncidenceItem(draftItem);
    }
    if (m_itemsToMove.isEmpty()) {
        complete();
        return;
    }
    for (auto &related : m_itemsToMove) {
        if (related.id() == item.id()) {
            related = item;
        }
    }
    auto job = moveItems(m_itemsToMove, m_destination);
    connect(job, &KJob::result, this, [this, item](KJob *job) {
        if (!m_saving) {
            return;
        }
        if (job->error()) {
            complete(i18n("The incidence was saved, but could not be moved: %1", job->errorString()));
            return;
        }
        auto movedItem = item;
        movedItem.setParentCollection(m_destination);
        if (m_wrapper) {
            movedItem.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(item.payload<KCalendarCore::Incidence::Ptr>()->clone()));
            m_wrapper->setIncidenceItem(movedItem);
        }
        complete();
    });
}

void CalendarEditorBackend::complete(const QString &error)
{
    setErrorMessage(error);
    m_changeId = -1;
    m_itemsToMove.clear();
    m_wrapper = nullptr;
    m_saving = false;
    Q_EMIT savingChanged();
    if (error.isEmpty()) {
        Q_EMIT finished();
    }
}

#include "moc_calendareditorbackend.cpp"
