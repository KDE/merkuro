// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "mailmodel.h"
#include <Akonadi/CollectionFilterProxyModel>
#include <MailCommon/EntityCollectionOrderProxyModel>
#include <QObject>
#include <qqmlregistration.h>

namespace Akonadi
{
class CollectionFilterProxyModel;
class Session;
}

namespace MailCommon
{
class EntityCollectionOrderProxyModel;
}

class QItemSelectionModel;

/// Class responsible for exposing the email folder selected by the user
class MailManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(MailCommon::EntityCollectionOrderProxyModel *foldersModel READ foldersModel CONSTANT)
    Q_PROPERTY(QItemSelectionModel *collectionSelectionModel READ collectionSelectionModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel *entryTreeModel READ entryTreeModel CONSTANT)

public:
    explicit MailManager(QObject *parent = nullptr);
    ~MailManager() override = default;

    void loadConfig();
    void saveConfig();

    QItemSelectionModel *collectionSelectionModel() const;
    Akonadi::EntityTreeModel *entryTreeModel() const;

    [[nodiscard]] bool loading() const;
    MailCommon::EntityCollectionOrderProxyModel *foldersModel() const;
    Akonadi::Session *session() const;

    Q_INVOKABLE void loadMailCollection(const QModelIndex &index);
    Q_INVOKABLE void moveToTrash(Akonadi::Item item);
    Q_INVOKABLE void updateCollection(const QModelIndex &index);
    Q_INVOKABLE void addCollection(const QModelIndex &index, const QVariant &name);
    Q_INVOKABLE void deleteCollection(const QModelIndex &index);
    Q_INVOKABLE void editCollection(const QModelIndex &index);
    [[nodiscard]] Q_INVOKABLE QString resourceIdentifier(const QModelIndex &index);
    Q_INVOKABLE void saveMail(const QUrl &fileUrl, const Akonadi::Item &item);
    Q_INVOKABLE void checkMail();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();
    void collectionSelectionModelChanged();
    void errorOccurred(const QString &error);

private:
    bool m_loading;
    Akonadi::Session *m_session;
    MailCommon::EntityCollectionOrderProxyModel *m_foldersModel;

    // folders
    QItemSelectionModel *m_collectionSelectionModel;
    Akonadi::EntityTreeModel *m_entityTreeModel;
};
