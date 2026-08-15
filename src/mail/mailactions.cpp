// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailactions.h"
#include "abstractmailmodel.h"
#include "mailkernel.h"
#include "merkuro_mail_debug.h"

#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemCopyJob>
#include <Akonadi/ItemDeleteJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemMoveJob>
#include <Akonadi/MessageStatus>
#include <KMime/Message>
#include <MailCommon/MailKernel>
#include <MessageComposer/MessageFactoryNG>

#include <KAuthorized>
#include <KLocalizedString>

#include <memory>

using namespace Qt::StringLiterals;

MailActions::MailActions(QObject *parent)
    : QObject(parent)
{
}

QItemSelectionModel *MailActions::selectionModel() const
{
    return m_selectionModel;
}

void MailActions::setSelectionModel(QItemSelectionModel *selectionModel)
{
    if (selectionModel == m_selectionModel) {
        return;
    }

    if (m_selectionModel) {
        disconnect(m_selectionModel, &QItemSelectionModel::selectionChanged, this, nullptr);
        disconnect(m_selectionModel, &QItemSelectionModel::currentChanged, this, nullptr);
    }

    m_selectionModel = selectionModel;
    Q_EMIT selectionModelChanged();

    setActionState();

    if (m_selectionModel) {
        connect(m_selectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
            Q_UNUSED(selected);
            Q_UNUSED(deselected);
            setActionState();
        });
        connect(m_selectionModel, &QItemSelectionModel::currentChanged, this, [this](const QModelIndex &selected, const QModelIndex &deselected) {
            Q_UNUSED(selected);
            Q_UNUSED(deselected);
            setActionState();
        });
    }
}

Akonadi::Item MailActions::item() const
{
    return m_item;
}

void MailActions::setItem(const Akonadi::Item &item)
{
    if (m_item == item) {
        return;
    }
    m_item = item;
    Q_EMIT itemChanged();
}

void MailActions::unsetItem()
{
    m_item = {};
    Q_EMIT itemChanged();
}

MailApplication *MailActions::mailApplication() const
{
    return m_mailApplication;
}

Akonadi::Item::List MailActions::selectionToItems() const
{
    if (m_item.isValid()) {
        return {m_item};
    }

    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();
    Akonadi::Item::List items;
    for (const auto &index : std::as_const(indexes)) {
        if (!index.isValid()) {
            continue;
        }

        const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (!items.contains(item)) {
            items << item;
        }
    }
    return items;
}

void MailActions::setMailApplication(MailApplication *mailApplication)
{
    if (mailApplication == m_mailApplication) {
        return;
    }
    Q_ASSERT(!m_mailApplication); // should only be set once
    m_mailApplication = mailApplication;
    Q_EMIT mailApplicationChanged();

    m_markReadAction = mailApplication->action("mark_read"_L1);
    connect(m_markReadAction, &QAction::triggered, this, [this] {
        setReadState(true);
    });

    m_markUnreadAction = mailApplication->action("mark_unread"_L1);
    connect(m_markUnreadAction, &QAction::triggered, this, [this] {
        setReadState(false);
    });

    m_markImportantAction = mailApplication->action("mark_important"_L1);
    connect(m_markImportantAction, &QAction::toggled, this, &MailActions::setImportantState);

    m_mailTrashAction = mailApplication->action("mail_trash"_L1);
    connect(m_mailTrashAction, &QAction::triggered, this, &MailActions::slotTrash);

    m_mailDeleteAction = mailApplication->action("mail_delete"_L1);
    connect(m_mailDeleteAction, &QAction::triggered, this, &MailActions::slotDelete);

    m_mailSaveAsAction = mailApplication->action("mail_save_as"_L1);
    connect(m_mailSaveAsAction, &QAction::triggered, this, [this] {
        const auto index = m_selectionModel->currentIndex();
        if (!index.isValid()) {
            return;
        }
        auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        Q_EMIT mailSaveAs(item);
    });

    m_mailMoveToAction = mailApplication->action("mail_move_to"_L1);
    connect(m_mailMoveToAction, &QAction::triggered, this, [this] {
        Q_EMIT moveToRequested(selectionToItems());
    });

    m_mailCopyToAction = mailApplication->action("mail_copy_to"_L1);
    connect(m_mailCopyToAction, &QAction::triggered, this, [this] {
        Q_EMIT copyToRequested(selectionToItems());
    });

    m_mailReplyAction = mailApplication->action("mail_reply"_L1);
    connect(m_mailReplyAction, &QAction::triggered, this, [this] {
        const auto items = selectionToItems();
        if (!items.isEmpty()) {
            replyToSender(items.first());
        }
    });

    m_mailReplyAllAction = mailApplication->action("mail_reply_all"_L1);
    connect(m_mailReplyAllAction, &QAction::triggered, this, [this] {
        const auto items = selectionToItems();
        if (!items.isEmpty()) {
            replyToAll(items.first());
        }
    });

    m_mailForwardAction = mailApplication->action("mail_forward"_L1);
    connect(m_mailForwardAction, &QAction::triggered, this, [this] {
        const auto items = selectionToItems();
        if (!items.isEmpty()) {
            forward(items.first());
        }
    });

    setActionState();
}

void MailActions::setActionState()
{
    if (!m_selectionModel || !m_mailApplication) {
        return;
    }

    bool allRead = true;
    bool allUnread = true;
    bool allImportant = true;
    bool allUnimportant = true;
    bool allInTrash = true;

    const auto items = selectionToItems();
    for (const auto &item : items) {
        Akonadi::MessageStatus state;
        state.setStatusFromFlags(item.flags());

        allRead = allRead && state.isRead();
        allUnread = allUnread && !state.isRead();
        allImportant = allImportant && state.isImportant();
        allUnimportant = allUnimportant && !state.isImportant();
        allInTrash = allInTrash && CommonKernel->folderIsTrash(item.parentCollection());
    }
    m_markReadAction->setEnabled(!allRead);
    m_markUnreadAction->setEnabled(!allUnread);
    m_markImportantAction->setChecked(allImportant);

    m_mailSaveAsAction->setVisible(items.size() == 1);
    m_mailDeleteAction->setVisible(allInTrash);
    m_mailTrashAction->setVisible(!allInTrash);
}

void MailActions::modifyStatus(const std::function<Akonadi::MessageStatus(Akonadi::MessageStatus)> &f)
{
    Q_ASSERT(m_selectionModel);

    const auto items = selectionToItems();
    for (const auto &item : items) {
        Akonadi::MessageStatus state;
        state.setStatusFromFlags(item.flags());

        const auto newState = f(state);

        if (state != newState) {
            auto newItem = item;
            newItem.setFlags(newState.statusFlags());
            auto job = new Akonadi::ItemModifyJob(newItem, this);
            job->disableRevisionCheck();
            job->setIgnorePayload(true);
            connect(job, &Akonadi::ItemModifyJob::result, this, [this](KJob *job) {
                if (job->error()) {
                    Q_EMIT m_mailApplication->errorOccurred(job->errorText());
                }
            });
            job->start();
        }
    }
}

void MailActions::setReadState(bool isRead)
{
    modifyStatus([isRead](Akonadi::MessageStatus status) -> Akonadi::MessageStatus {
        status.setRead(isRead);
        return status;
    });
}

void MailActions::setImportantState(bool isImportant)
{
    modifyStatus([isImportant](Akonadi::MessageStatus status) -> Akonadi::MessageStatus {
        status.setImportant(isImportant);
        return status;
    });
}

void MailActions::slotTrash()
{
    const auto items = selectionToItems();

    QHash<Akonadi::Collection, Akonadi::Item::List> itemCollections;
    for (const auto &item : items) {
        const auto collection = item.parentCollection();
        auto trash = CommonKernel->trashCollectionFromResource(collection);
        if (!trash.isValid()) {
            trash = CommonKernel->trashCollectionFolder();
        }

        // we might be in a search model and have results in multiple resources
        itemCollections[trash] << item;
    }

    for (const auto &[trash, items] : itemCollections.asKeyValueRange()) {
        auto job = new Akonadi::ItemMoveJob(items, trash);
        connect(job, &KJob::result, this, [this](KJob *job) {
            if (job->error()) {
                Q_EMIT m_mailApplication->errorOccurred(job->errorText());
            }
        });
    }
}

void MailActions::slotDelete()
{
    const auto items = selectionToItems();

    for (const auto &item : items) {
        auto job = new Akonadi::ItemDeleteJob(item);
        connect(job, &KJob::result, this, [this](KJob *job) {
            if (job->error()) {
                Q_EMIT m_mailApplication->errorOccurred(job->errorText());
            }
        });
    }
}

void MailActions::moveTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    if (!(destination.rights() & Akonadi::Collection::CanCreateItem)) {
        qCWarning(MERKURO_MAIL_LOG) << "Unable to move items to unwritable location" << destination;
        return;
    }

    auto job = new Akonadi::ItemMoveJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            Q_EMIT m_mailApplication->errorOccurred(job->errorText());
        }
    });
}

void MailActions::replyToSender(const Akonadi::Item &item)
{
    replyTo(item, MessageComposer::ReplySmart);
}

void MailActions::replyToAll(const Akonadi::Item &item)
{
    replyTo(item, MessageComposer::ReplyAll);
}

void MailActions::replyTo(const Akonadi::Item &item, MessageComposer::ReplyStrategy strategy)
{
    auto fetchJob = new Akonadi::ItemFetchJob(item, this);
    fetchJob->fetchScope().fetchFullPayload(true);
    connect(fetchJob, &Akonadi::ItemFetchJob::result, this, [this, strategy](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        if (job->error()) {
            if (m_mailApplication) {
                Q_EMIT m_mailApplication->errorOccurred(job->errorText());
            }
            return;
        }
        if (fetchJob->items().isEmpty()) {
            return;
        }
        const auto fetchedItem = fetchJob->items().first();
        if (!fetchedItem.hasPayload<std::shared_ptr<KMime::Message>>()) {
            return;
        }
        const auto msg = fetchedItem.payload<std::shared_ptr<KMime::Message>>();

        auto factory = new MessageComposer::MessageFactoryNG(msg, fetchedItem.id(), fetchedItem.parentCollection(), this);
        factory->setIdentityManager(MailKernel::self().identityManager());
        factory->setReplyStrategy(strategy);

        connect(factory,
                &MessageComposer::MessageFactoryNG::createReplyDone,
                this,
                [this, factory](const MessageComposer::MessageFactoryNG::MessageReply &reply) {
                    factory->deleteLater();
                    if (!reply.msg) {
                        return;
                    }
                    const QString to = reply.msg->to()->asUnicodeString();
                    const QString subject = reply.msg->subject()->asUnicodeString();
                    KMime::Content *textPart = reply.msg->mainBodyPart("text/plain");
                    const QString body = textPart ? textPart->decodedText() : QString::fromUtf8(reply.msg->body());
                    Q_EMIT composerRequested(to, subject, body);
                });
        factory->createReplyAsync();
    });
}

void MailActions::forward(const Akonadi::Item &item)
{
    auto fetchJob = new Akonadi::ItemFetchJob(item, this);
    fetchJob->fetchScope().fetchFullPayload(true);
    connect(fetchJob, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        if (job->error()) {
            if (m_mailApplication) {
                Q_EMIT m_mailApplication->errorOccurred(job->errorText());
            }
            return;
        }
        if (fetchJob->items().isEmpty()) {
            return;
        }
        const auto fetchedItem = fetchJob->items().first();
        if (!fetchedItem.hasPayload<std::shared_ptr<KMime::Message>>()) {
            return;
        }
        const auto msg = fetchedItem.payload<std::shared_ptr<KMime::Message>>();

        auto factory = new MessageComposer::MessageFactoryNG(msg, fetchedItem.id(), fetchedItem.parentCollection(), this);
        factory->setIdentityManager(MailKernel::self().identityManager());

        connect(factory, &MessageComposer::MessageFactoryNG::createForwardDone, this, [this, factory](const std::shared_ptr<KMime::Message> &fwdMsg) {
            factory->deleteLater();
            if (!fwdMsg) {
                return;
            }
            const QString subject = fwdMsg->subject()->asUnicodeString();
            KMime::Content *textPart = fwdMsg->mainBodyPart("text/plain");
            const QString body = textPart ? textPart->decodedText() : QString::fromUtf8(fwdMsg->body());
            Q_EMIT composerRequested(QString{}, subject, body);
        });
        factory->createForwardAsync();
    });
}

void MailActions::copyTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    if (!(destination.rights() & Akonadi::Collection::CanCreateItem)) {
        qCWarning(MERKURO_MAIL_LOG) << "Unable to copy items to unwritable location" << destination;
        return;
    }

    auto job = new Akonadi::ItemCopyJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            Q_EMIT m_mailApplication->errorOccurred(job->errorText());
        }
    });
}

#include "moc_mailactions.cpp"
