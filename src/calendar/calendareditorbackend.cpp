// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "calendareditorbackend.h"
#include "calendarincidencejob.h"
#include "calendarmanager.h"
#include "incidencewrapper.h"

#include <KJob>
#include <KLocalizedString>

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
        disconnect(m_manager, nullptr, this, nullptr);
    }
    m_manager = manager;
    if (m_manager) {
        connect(m_manager, &QObject::destroyed, this, &CalendarEditorBackend::calendarManagerChanged);
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

void CalendarEditorBackend::save(IncidenceWrapper *wrapper, bool editMode)
{
    if (m_saving) {
        return;
    }
    setErrorMessage({});
    if (wrapper && wrapper->incidencePtr() && wrapper->summary().trimmed().isEmpty()) {
        setErrorMessage(i18n("Please enter a title."));
        return;
    }
    auto job = createJob();
    if (!job->prepareSave(wrapper, editMode)) {
        setErrorMessage(job->errorText());
        delete job;
        return;
    }
    m_saving = true;
    Q_EMIT savingChanged();
    connect(job, &KJob::result, this, [this](KJob *job) {
        setErrorMessage(job->error() ? job->errorText() : QString());
        m_saving = false;
        Q_EMIT savingChanged();
        if (!job->error()) {
            Q_EMIT finished();
        }
    });
    job->start();
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

CalendarIncidenceJob *CalendarEditorBackend::createJob()
{
    return new CalendarIncidenceJob(m_manager, this);
}

#include "moc_calendareditorbackend.cpp"
