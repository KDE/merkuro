// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "mailmodel.h"
#include <Akonadi/CollectionFilterProxyModel>
#include <MailCommon/EntityCollectionOrderProxyModel>
#include <QObject>

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
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(MailCommon::EntityCollectionOrderProxyModel *foldersModel READ foldersModel CONSTANT)
    Q_PROPERTY(MailModel *folderModel READ folderModel NOTIFY folderModelChanged)
    Q_PROPERTY(QString selectedFolderName READ selectedFolderName NOTIFY selectedFolderNameChanged)

public:
    explicit MailManager(QObject *parent = nullptr);
    ~MailManager() override = default;

    void loadConfig();
    void saveConfig();

    bool loading() const;
    MailCommon::EntityCollectionOrderProxyModel *foldersModel() const;
    MailModel *folderModel() const;
    Akonadi::Session *session() const;
    [[nodiscard]] QString selectedFolderName() const;

    Q_INVOKABLE void loadMailCollection(const QModelIndex &index);
    Q_INVOKABLE void moveToTrash(Akonadi::Item item);
    Q_INVOKABLE void updateCollection(const QModelIndex &index);
    Q_INVOKABLE void addCollection(const QModelIndex &index, const QVariant &name);
    Q_INVOKABLE void deleteCollection(const QModelIndex &index);
    Q_INVOKABLE void editCollection(const QModelIndex &index);
    Q_INVOKABLE QString resourceIdentifier(const QModelIndex &index);
    Q_INVOKABLE void saveMail(const QUrl &fileUrl, const Akonadi::Item &item);

Q_SIGNALS:
    void loadingChanged();
    void folderModelChanged();
    void selectedFolderNameChanged();

private:
    bool m_loading;
    Akonadi::Session *m_session;
    MailCommon::EntityCollectionOrderProxyModel *m_foldersModel;

    // folders
    QItemSelectionModel *m_collectionSelectionModel;
    MailModel *m_folderModel;
    QString m_selectedFolderName;
};
