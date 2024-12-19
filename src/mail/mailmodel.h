// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Akonadi/Item>

#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>

#include "abstractmailmodel.h"
#include "messagestatus.h"

class MailModel : public Akonadi::EntityMimeTypeFilterModel, AbstractMailModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString folderName READ folderName NOTIFY folderNameChanged)
    Q_PROPERTY(
        QItemSelectionModel *collectionSelectionModel READ collectionSelectionModel WRITE setCollectionSelectionModel NOTIFY collectionSelectionModelChanged)
    Q_PROPERTY(Akonadi::EntityTreeModel *entryTreeModel READ entryTreeModel WRITE setEntityTreeModel NOTIFY entityTreeModelChanged)

public:
    enum ExtraRole {
        TitleRole = Qt::UserRole + 1,
        SenderRole,
        FromRole,
        ToRole,
        TextColorRole,
        DateRole,
        DateTimeRole,
        BackgroundColorRole,
        StatusRole,
        FavoriteRole,
        ItemRole,
    };

    explicit MailModel(QObject *parent = nullptr);

    [[nodiscard]] QItemSelectionModel *collectionSelectionModel() const;
    void setCollectionSelectionModel(QItemSelectionModel *collectionSelectionModel);

    [[nodiscard]] Akonadi::EntityTreeModel *entryTreeModel() const;
    void setEntityTreeModel(Akonadi::EntityTreeModel *entryTreeModel);

    [[nodiscard]] QString folderName() const;

    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void updateMessageStatus(int row, MessageStatus messageStatus);
    Q_INVOKABLE MessageStatus copyMessageStatus(MessageStatus messageStatus);

Q_SIGNALS:
    void collectionSelectionModelChanged();
    void entityTreeModelChanged();
    void folderNameChanged();

private:
    void setupModel();

    QItemSelectionModel *m_collectionSelectionModel = nullptr;
    Akonadi::EntityTreeModel *m_entityTreeModel = nullptr;
    Akonadi::Item itemForRow(int row) const;
    QString m_searchString;
    QString m_folderName;
};
