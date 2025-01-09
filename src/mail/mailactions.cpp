// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailactions.h"
#include "abstractmailmodel.h"
#include "mailkernel.h"

#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemCopyJob>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemMoveJob>
#include <Akonadi/MessageStatus>
#include <MailCommon/MailKernel>

#include <KAuthorized>
#include <KLocalizedString>

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

MailApplication *MailActions::mailApplication() const
{
    return m_mailApplication;
}

static Akonadi::Item::List selectionToItems(QItemSelectionModel *selectionModel)
{
    auto indexes = selectionModel->selectedIndexes();
    indexes << selectionModel->currentIndex();
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

    m_mailDeleteAction = mailApplication->action("mail_trash"_L1);
    connect(m_mailDeleteAction, &QAction::triggered, this, &MailActions::slotTrash);

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
        Q_EMIT moveToRequested(selectionToItems(m_selectionModel));
    });

    m_mailCopyToAction = mailApplication->action("mail_copy_to"_L1);
    connect(m_mailCopyToAction, &QAction::triggered, this, [this] {
        Q_EMIT copyToRequested(selectionToItems(m_selectionModel));
    });

    setActionState();
}

void MailActions::setActionState()
{
    if (!m_selectionModel || !m_mailApplication) {
        return;
    }

    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();

    bool allRead = true;
    bool allUnread = true;
    bool allImportant = true;
    bool allUnimportant = true;

    const AbstractMailModel *mailModel = nullptr;
    for (const auto &index : indexes) {
        if (!index.isValid()) {
            return;
        }
        if (!mailModel) {
            mailModel = dynamic_cast<const AbstractMailModel *>(index.model());
            Q_ASSERT(mailModel);
        }

        auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        auto state = mailModel->dataFromItem(item, AbstractMailModel::StatusRole).value<Akonadi::MessageStatus>();

        allRead = allRead && state.isRead();
        allUnread = allUnread && !state.isRead();
        allImportant = allImportant && state.isImportant();
        allUnimportant = allUnimportant && !state.isImportant();
    }

    m_markReadAction->setText(i18ncp("@action:inmenu", "Mark Message as Read", "Mark Messages as Read", indexes.size()));
    m_markReadAction->setEnabled(!allRead);

    m_markUnreadAction->setText(i18ncp("@action:inmenu", "Mark Message as Unread", "Mark Messages as Unread", indexes.size()));
    m_markUnreadAction->setEnabled(!allUnread);

    m_markImportantAction->setText(i18ncp("@action:inmenu", "Mark Message as Important", "Mark Messages as Important", indexes.size()));
    m_markImportantAction->setChecked(allImportant);

    m_mailSaveAsAction->setVisible(indexes.size() == 1);
}

void MailActions::modifyStatus(std::function<Akonadi::MessageStatus(Akonadi::MessageStatus)> f)
{
    Q_ASSERT(m_selectionModel);

    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();

    const AbstractMailModel *mailModel = nullptr;
    for (const auto &index : indexes) {
        if (!index.isValid()) {
            return;
        }
        if (!mailModel) {
            mailModel = dynamic_cast<const AbstractMailModel *>(index.model());
            Q_ASSERT(mailModel);
        }

        auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto state = mailModel->dataFromItem(item, AbstractMailModel::StatusRole).value<Akonadi::MessageStatus>();

        const auto newState = f(state);

        if (state != newState) {
            item.setFlags(newState.statusFlags());
            auto job = new Akonadi::ItemModifyJob(item, this);
            job->disableRevisionCheck();
            job->setIgnorePayload(true);
            connect(job, &Akonadi::ItemModifyJob::result, this, [this](KJob *job) {
                if (job->error()) {
                    m_mailApplication->errorOccurred(job->errorText());
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
    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();

    const AbstractMailModel *mailModel = nullptr;
    QHash<Akonadi::Collection, Akonadi::Item::List> itemCollections;
    for (const auto &index : indexes) {
        if (!index.isValid()) {
            return;
        }
        if (!mailModel) {
            mailModel = dynamic_cast<const AbstractMailModel *>(index.model());
            Q_ASSERT(mailModel);
        }

        const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

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
                m_mailApplication->errorOccurred(job->errorText());
            }
        });
    }
}

void MailActions::moveTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    auto job = new Akonadi::ItemMoveJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            m_mailApplication->errorOccurred(job->errorText());
        }
    });
}
void MailActions::copyTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    auto job = new Akonadi::ItemCopyJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            m_mailApplication->errorOccurred(job->errorText());
        }
    });
}
