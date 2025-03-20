// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/Item>
#include <QObject>
#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

namespace Akonadi
{
class ETMViewStateSaver;
class EntityMimeTypeFilterModel;
}
class KCheckableProxyModel;
class QAbstractItemModel;
class QItemSelectionModel;
class ColorProxyModel;

class ContactManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// Model for getting the contact collections available for the mainDrawer
    Q_PROPERTY(QAbstractItemModel *contactCollections READ contactCollections CONSTANT)

    /// Model containing the contacts from the selected collection
    Q_PROPERTY(QAbstractItemModel *filteredContacts READ filteredContacts CONSTANT)
public:
    explicit ContactManager(QObject *parent = nullptr);
    ~ContactManager() override;
    QAbstractItemModel *contactCollections() const;
    QAbstractItemModel *filteredContacts() const;

    Q_INVOKABLE Akonadi::Item getItem(qint64 itemId);

    Q_INVOKABLE void setCollectionColor(Akonadi::Collection collection, const QColor &color);
    Q_INVOKABLE void deleteItem(const Akonadi::Item &item);
    Q_INVOKABLE void updateAllCollections();
    Q_INVOKABLE void updateCollection(const Akonadi::Collection &collection);
    Q_INVOKABLE void deleteCollection(const Akonadi::Collection &collection);
    Q_INVOKABLE void editCollection(const Akonadi::Collection &collection);
    Q_INVOKABLE QVariantMap getCollectionDetails(const Akonadi::Collection &collection);

private:
    void saveState() const;

    Akonadi::EntityMimeTypeFilterModel *const m_collectionTree;
    QItemSelectionModel *m_collectionSelectionModel = nullptr;
    Akonadi::ETMViewStateSaver *m_collectionSelectionModelStateSaver = nullptr;
    QSortFilterProxyModel *m_filteredContacts = nullptr;
    KCheckableProxyModel *m_checkableProxyModel = nullptr;
    ColorProxyModel *m_colorProxy = nullptr;
};
