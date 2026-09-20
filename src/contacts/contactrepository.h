// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QColor>
#include <QObject>

class QAbstractItemModel;
class QItemSelectionModel;
class QSortFilterProxyModel;
class KCheckableProxyModel;
class ColorProxyModel;

namespace Akonadi
{
class ChangeRecorder;
class ContactsTreeModel;
class ETMViewStateSaver;
class EntityMimeTypeFilterModel;
class Session;
}

class ContactRepository : public QObject
{
    Q_OBJECT

public:
    explicit ContactRepository(QObject *parent = nullptr);
    ~ContactRepository() override;

    QAbstractItemModel *contactCollections() const;
    QAbstractItemModel *filteredContacts() const;
    QColor collectionColor(qint64 collectionId) const;
    void setCollectionColor(qint64 collectionId, const QColor &color);

Q_SIGNALS:
    void errorOccurred(const QString &error);

private:
    void saveState() const;

    Akonadi::Session *const m_session;
    Akonadi::ChangeRecorder *const m_monitor;
    Akonadi::ContactsTreeModel *const m_contactModel;
    Akonadi::EntityMimeTypeFilterModel *const m_collectionTree;
    QItemSelectionModel *m_collectionSelectionModel = nullptr;
    Akonadi::ETMViewStateSaver *m_collectionSelectionModelStateSaver = nullptr;
    QSortFilterProxyModel *m_filteredContacts = nullptr;
    KCheckableProxyModel *m_checkableProxyModel = nullptr;
    ColorProxyModel *m_colorProxy = nullptr;
};
