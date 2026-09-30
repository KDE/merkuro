// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/IncidenceChanger>
#include <QObject>
#include <QPointer>
#include <qqmlintegration.h>

class CalendarManager;
class IncidenceWrapper;
class KJob;

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
    // Operation boundaries allow tests to control completion and failure order.
    virtual int createIncidence(const KCalendarCore::Incidence::Ptr &incidence, const Akonadi::Collection &collection);
    virtual int modifyIncidence(const Akonadi::Item &item, const KCalendarCore::Incidence::Ptr &original);
    virtual KJob *moveItems(const Akonadi::Item::List &items, const Akonadi::Collection &collection);

private:
    void changeFinished(int changeId, const Akonadi::Item &item, Akonadi::IncidenceChanger::ResultCode result, const QString &error);
    void complete(const QString &error = {});
    void setErrorMessage(const QString &error);
    Akonadi::Item::List relatedItems(const Akonadi::Item &item) const;

    QPointer<CalendarManager> m_manager;
    QPointer<IncidenceWrapper> m_wrapper;
    bool m_saving = false;
    bool m_editMode = false;
    int m_changeId = -1;
    QString m_errorMessage;
    Akonadi::Collection m_destination;
    Akonadi::Item::List m_itemsToMove;
};
