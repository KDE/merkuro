// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mailactions.h"
#include "mailmodel.h"

#include <Akonadi/ItemModifyJob>
#include <Akonadi/MessageStatus>

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
    m_selectionModel = selectionModel;
    Q_EMIT selectionModelChanged();
}

void MailActions::modifyStatus(const QModelIndexList &indexes, std::function<Akonadi::MessageStatus(Akonadi::MessageStatus)> f)
{
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

        auto newState = f(state);
        if (state != newState) {
            item.setFlags(state.statusFlags());
            auto job = new Akonadi::ItemModifyJob(item, this);
            job->disableRevisionCheck();
            job->setIgnorePayload(true);
            connect(job, &Akonadi::ItemModifyJob::result, this, [](KJob *job) {
                if (job->error()) {
                    qWarning() << job->errorText();
                }
            });
            job->start();
        }
    }
}

void MailActions::setReadState(bool isRead)
{
    Q_ASSERT(m_selectionModel);

    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();

    modifyStatus(indexes, [isRead](Akonadi::MessageStatus status) -> Akonadi::MessageStatus {
        status.setRead(isRead);
        return status;
    });
}

void MailActions::setImportantState(bool isImportant)
{
    Q_ASSERT(m_selectionModel);

    auto indexes = m_selectionModel->selectedIndexes();
    indexes << m_selectionModel->currentIndex();

    modifyStatus(indexes, [isImportant](Akonadi::MessageStatus status) -> Akonadi::MessageStatus {
        status.setImportant(isImportant);
        return status;
    });
}
