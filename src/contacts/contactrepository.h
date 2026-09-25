// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QColor>
#include <QObject>

#include "merkuro_contact_export.h"

class QAbstractItemModel;
class QItemSelectionModel;
class QSortFilterProxyModel;
class KCheckableProxyModel;
class ColorProxyModel;
class ContactListProxyModel;
class BirthdayCalendar;

namespace Akonadi
{
class ChangeRecorder;
class ContactsTreeModel;
class ETMViewStateSaver;
class EntityMimeTypeFilterModel;
class SelectionProxyModel;
class Session;
}

class MERKURO_CONTACT_EXPORT ContactRepository : public QObject
{
    Q_OBJECT

public:
    explicit ContactRepository(QObject *parent = nullptr);
    ~ContactRepository() override;

    QAbstractItemModel *contactCollections() const;
    ContactListProxyModel *filteredContacts() const;
    qint64 selectedCollectionId() const;
    bool showBirthdays() const;
    void setShowBirthdays(bool enabled);
    QColor collectionColor(qint64 collectionId) const;
    void setCollectionColor(qint64 collectionId, const QColor &color);

Q_SIGNALS:
    void errorOccurred(const QString &error);

private:
    void saveState() const;

    Akonadi::Session *const m_session;
    Akonadi::ChangeRecorder *const m_monitor;
    Akonadi::ContactsTreeModel *const m_contactModel;
    Akonadi::SelectionProxyModel *m_selectionProxyModel = nullptr;
    Akonadi::EntityMimeTypeFilterModel *const m_collectionTree;
    QItemSelectionModel *m_collectionSelectionModel = nullptr;
    Akonadi::ETMViewStateSaver *m_collectionSelectionModelStateSaver = nullptr;
    ContactListProxyModel *m_filteredContacts = nullptr;
    QAbstractItemModel *m_selectedContacts = nullptr;
    QAbstractItemModel *m_allContacts = nullptr;
    BirthdayCalendar *m_birthdayCalendar = nullptr;
    bool m_showBirthdays = false;
    KCheckableProxyModel *m_checkableProxyModel = nullptr;
    ColorProxyModel *m_colorProxy = nullptr;
};
