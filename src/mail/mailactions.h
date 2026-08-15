// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "mailapplication.h"

#include <Akonadi/Item>
#include <MessageComposer/MessageFactoryNG>

#include <QItemSelectionModel>
#include <QObject>
#include <qqmlregistration.h>

namespace Akonadi
{
class MessageStatus;
}

// TODO this should interact with MailApplications
class MailActions : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QItemSelectionModel *selectionModel READ selectionModel WRITE setSelectionModel NOTIFY selectionModelChanged)
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem RESET unsetItem NOTIFY itemChanged)
    Q_PROPERTY(MailApplication *mailApplication READ mailApplication WRITE setMailApplication NOTIFY mailApplicationChanged)

public:
    explicit MailActions(QObject *parent = nullptr);

    QItemSelectionModel *selectionModel() const;
    void setSelectionModel(QItemSelectionModel *selectionModel);

    Akonadi::Item item() const;
    void setItem(const Akonadi::Item &item);
    void unsetItem();

    MailApplication *mailApplication() const;
    void setMailApplication(MailApplication *mailApplication);

    Q_INVOKABLE void setReadState(bool isRead);
    Q_INVOKABLE void setImportantState(bool isImportant);
    Q_INVOKABLE void setActionState();
    Q_INVOKABLE void moveTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination);
    Q_INVOKABLE void copyTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination);
    Q_INVOKABLE void replyToSender(const Akonadi::Item &item);
    Q_INVOKABLE void replyToAll(const Akonadi::Item &item);
    Q_INVOKABLE void forward(const Akonadi::Item &item);

    Q_INVOKABLE Akonadi::Item::List selectionToItems() const;

Q_SIGNALS:
    void selectionModelChanged();
    void mailApplicationChanged();
    void itemChanged();

    void mailSaveAs(const Akonadi::Item &item);
    void moveToRequested(const Akonadi::Item::List &items);
    void copyToRequested(const Akonadi::Item::List &items);
    void composerRequested(const QString &to, const QString &subject, const QString &body);

private:
    void modifyStatus(const std::function<Akonadi::MessageStatus(Akonadi::MessageStatus)> &f);
    void slotTrash();
    void replyTo(const Akonadi::Item &item, MessageComposer::ReplyStrategy strategy);

    QItemSelectionModel *m_selectionModel = nullptr;
    MailApplication *m_mailApplication = nullptr;
    Akonadi::Item m_item;

    QAction *m_markReadAction = nullptr;
    QAction *m_markUnreadAction = nullptr;
    QAction *m_markImportantAction = nullptr;
    QAction *m_markUnimportantAction = nullptr;
    QAction *m_mailDeleteAction = nullptr;
    QAction *m_mailSaveAsAction = nullptr;
    QAction *m_mailMoveToAction = nullptr;
    QAction *m_mailCopyToAction = nullptr;
    QAction *m_mailReplyAction = nullptr;
    QAction *m_mailReplyAllAction = nullptr;
    QAction *m_mailForwardAction = nullptr;
};
