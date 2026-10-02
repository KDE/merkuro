// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <qqmlintegration.h>

class CalendarManager;
class IncidenceWrapper;
class CalendarIncidenceJob;

class CalendarEditorBackend : public QObject
{
    Q_OBJECT
    Q_MOC_INCLUDE("calendarmanager.h")
    QML_ELEMENT
    Q_PROPERTY(CalendarManager *calendarManager READ calendarManager WRITE setCalendarManager NOTIFY calendarManagerChanged)
    Q_PROPERTY(bool saving READ saving NOTIFY savingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit CalendarEditorBackend(QObject *parent = nullptr);
    CalendarManager *calendarManager() const;
    void setCalendarManager(CalendarManager *manager);
    bool saving() const;
    QString errorMessage() const;

    Q_INVOKABLE void save(IncidenceWrapper *wrapper, bool editMode);
    Q_INVOKABLE void reload(IncidenceWrapper *wrapper);

Q_SIGNALS:
    void calendarManagerChanged();
    void savingChanged();
    void errorMessageChanged();
    void finished();

protected:
    virtual CalendarIncidenceJob *createJob();

private:
    void setErrorMessage(const QString &error);

    QPointer<CalendarManager> m_manager;
    bool m_saving = false;
    QString m_errorMessage;
};
