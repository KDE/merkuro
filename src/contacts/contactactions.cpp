// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactactions.h"
#include "merkuro_contact_debug.h"

#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemCopyJob>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemMoveJob>

#include <KAuthorized>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KLocalizedString>

using namespace Qt::StringLiterals;

ContactActions::ContactActions(QObject *parent)
    : QObject(parent)
{
}

QItemSelectionModel *ContactActions::selectionModel() const
{
    return m_selectionModel;
}

void ContactActions::setSelectionModel(QItemSelectionModel *selectionModel)
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

Akonadi::Item ContactActions::item() const
{
    return m_item;
}

void ContactActions::setItem(const Akonadi::Item &item)
{
    if (m_item == item) {
        return;
    }
    m_item = item;
    Q_EMIT itemChanged();
}

void ContactActions::unsetItem()
{
    m_item = {};
    Q_EMIT itemChanged();
}

ContactApplication *ContactActions::contactApplication() const
{
    return m_contactApplication;
}

Akonadi::Item::List ContactActions::selectionToItems() const
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

void ContactActions::setContactApplication(ContactApplication *ContactApplication)
{
    if (ContactApplication == m_contactApplication) {
        return;
    }
    Q_ASSERT(!m_contactApplication); // should only be set once
    m_contactApplication = ContactApplication;
    Q_EMIT contactApplicationChanged();

    m_contactMoveToAction = ContactApplication->action("contact_move_to"_L1);
    connect(m_contactMoveToAction, &QAction::triggered, this, [this] {
        Q_EMIT moveToRequested(selectionToItems());
    });

    m_contactCopyToAction = ContactApplication->action("contact_copy_to"_L1);
    connect(m_contactCopyToAction, &QAction::triggered, this, [this] {
        Q_EMIT copyToRequested(selectionToItems());
    });

    m_contactEditAction = ContactApplication->action("contact_edit"_L1);
    connect(m_contactEditAction, &QAction::triggered, this, [this] {
        const auto items = selectionToItems();
        if (items.isEmpty()) {
            return;
        }
        const auto &item = items.at(0);
        if (item.mimeType() == KContacts::Addressee::mimeType()) {
            Q_EMIT editContact(item.id());
        } else {
            Q_EMIT editContactGroup(item.id());
        }
    });

    m_contactDeleteAction = ContactApplication->action("contact_delete"_L1);
    connect(m_contactDeleteAction, &QAction::triggered, this, [this] {
        const auto items = selectionToItems();
        QStringList names;
        for (const auto &item : items) {
            if (item.hasPayload<KContacts::Addressee>()) {
                const auto addressee = item.payload<KContacts::Addressee>();
                if (!addressee.realName().isEmpty()) {
                    names << addressee.realName();
                } else if (!addressee.preferredEmail().isEmpty()) {
                    names << addressee.preferredEmail();
                } else if (!addressee.familyName().isEmpty()) {
                    names << addressee.familyName();
                } else {
                    names << i18nc("Placeholder when no name is set", "No name");
                }
            } else if (item.hasPayload<KContacts::ContactGroup>()) {
                const auto group = item.payload<KContacts::ContactGroup>();
                names << group.name();
            } else {
                names << i18n("Invalid item");
            }
        }
        Q_EMIT deleteRequested(selectionToItems(), names);
    });

    setActionState();
}

void ContactActions::setActionState()
{
    if (!m_selectionModel || !m_contactApplication) {
        return;
    }

    if (m_selectionModel->selectedIndexes().size() > 1) {
        m_contactEditAction->setEnabled(false);
    }
}

void ContactActions::moveTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    if (!(destination.rights() & Akonadi::Collection::CanCreateItem)) {
        qCWarning(MERKURO_CONTACT_LOG) << "Unable to move items to unwritable location" << destination;
        return;
    }

    auto job = new Akonadi::ItemMoveJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            m_contactApplication->errorOccurred(job->errorText());
        }
    });
}

void ContactActions::copyTo(const Akonadi::Item::List &items, const Akonadi::Collection &destination)
{
    if (!(destination.rights() & Akonadi::Collection::CanCreateItem)) {
        qCWarning(MERKURO_CONTACT_LOG) << "Unable to copy items to unwritable location" << destination;
        return;
    }

    auto job = new Akonadi::ItemCopyJob(items, destination);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            m_contactApplication->errorOccurred(job->errorText());
        }
    });
}

#include "moc_contactactions.cpp"
