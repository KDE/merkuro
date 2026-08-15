// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "abstractmailmodel.h"

#include <Akonadi/EntityTreeModel>
#include <MessageList/Aggregation>
#include <MessageList/MessageModel>
#include <QIdentityProxyModel>
#include <QItemSelectionModel>
#include <QPointer>
#include <qqmlregistration.h>

#include <memory>

class MailPresentationModel : public QIdentityProxyModel, public AbstractMailModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Akonadi::EntityTreeModel *entryTreeModel READ entryTreeModel WRITE setEntityTreeModel NOTIFY entityTreeModelChanged)
    Q_PROPERTY(QItemSelectionModel *collectionSelectionModel READ collectionSelectionModel WRITE setCollectionSelectionModel NOTIFY collectionSelectionModelChanged)
    Q_PROPERTY(MessageList::Core::Aggregation::Threading threading READ threading WRITE setThreading NOTIFY threadingChanged)

public:
    explicit MailPresentationModel(QObject *parent = nullptr);

    [[nodiscard]] Akonadi::EntityTreeModel *entryTreeModel() const;
    void setEntityTreeModel(Akonadi::EntityTreeModel *entityTreeModel);

    [[nodiscard]] QItemSelectionModel *collectionSelectionModel() const;
    void setCollectionSelectionModel(QItemSelectionModel *collectionSelectionModel);

    [[nodiscard]] MessageList::Core::Aggregation::Threading threading() const;
    void setThreading(MessageList::Core::Aggregation::Threading threading);

    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;

Q_SIGNALS:
    void entityTreeModelChanged();
    void collectionSelectionModelChanged();
    void threadingChanged();

private:
    [[nodiscard]] QVariant threadSectionDate(const QModelIndex &sourceIndex) const;

    std::unique_ptr<MessageList::MessageModel> m_messageModel;
    QPointer<Akonadi::EntityTreeModel> m_entityTreeModel;
    QPointer<QItemSelectionModel> m_collectionSelectionModel;
};
