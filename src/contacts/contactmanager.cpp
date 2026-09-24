// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>

// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmanager.h"

#include "contactrepository.h"
#include "merkuro_contact_debug.h"
#include <Akonadi/AgentManager>
#include <Akonadi/Collection>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionStatistics>
#include <Akonadi/CollectionUtils>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemDeleteJob>
#include <Akonadi/ItemMoveJob>
#include <KJob>
#include <KLocalizedString>

ContactManager::ContactManager(QObject *parent)
    : QObject(parent)
    , m_repository(new ContactRepository(this))
{
    connect(m_repository, &ContactRepository::errorOccurred, this, &ContactManager::errorOccurred);
}

ContactManager::~ContactManager() = default;

QAbstractItemModel *ContactManager::contactCollections() const
{
    return m_repository->contactCollections();
}

QAbstractItemModel *ContactManager::filteredContacts() const
{
    return m_repository->filteredContacts();
}

qint64 ContactManager::selectedCollectionId() const
{
    return m_repository->selectedCollectionId();
}

Akonadi::Item ContactManager::getItem(qint64 itemId)
{
    Akonadi::Item item(itemId);

    return item;
}

KJob *ContactManager::deleteItem(const Akonadi::Item &item)
{
    return new Akonadi::ItemDeleteJob(item);
}

void ContactManager::moveItemToCollection(const Akonadi::Item &item, const Akonadi::Collection &destination)
{
    if (!item.isValid() || !destination.isValid() || item.parentCollection() == destination) {
        return;
    }
    if (!(destination.rights() & Akonadi::Collection::CanCreateItem) || !destination.contentMimeTypes().contains(item.mimeType())) {
        Q_EMIT errorOccurred(i18n("The selected address book cannot store this contact."));
        return;
    }

    auto job = new Akonadi::ItemMoveJob(item, destination, this);
    connect(job, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            Q_EMIT errorOccurred(job->errorText());
        }
    });
}

void ContactManager::updateAllCollections()
{
    const auto collections = contactCollections();
    for (int i = 0, count = collections->rowCount(); i < count; i++) {
        auto collection = collections->data(collections->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}

void ContactManager::updateCollection(const Akonadi::Collection &collection)
{
    Akonadi::AgentManager::self()->synchronizeCollection(collection, false);
}

void ContactManager::deleteCollection(const Akonadi::Collection &collection)
{
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // deletes contents
        auto job = new Akonadi::CollectionDeleteJob(collection, this);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(MERKURO_CONTACT_LOG) << "Error occurred deleting collection: " << job->errorString();
            }
        });
        return;
    }
    // deletes the agent, not the contents
    const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

QVariantMap ContactManager::getCollectionDetails(const Akonadi::Collection &collection)
{
    QVariantMap collectionDetails;

    collectionDetails[QStringLiteral("id")] = collection.id();
    collectionDetails[QStringLiteral("name")] = collection.name();
    collectionDetails[QStringLiteral("displayName")] = collection.displayName();
    collectionDetails[QStringLiteral("color")] = m_repository->collectionColor(collection.id());
    collectionDetails[QStringLiteral("count")] = collection.statistics().count();
    collectionDetails[QStringLiteral("isResource")] = Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QStringLiteral("resource")] = collection.resource();
    collectionDetails[QStringLiteral("readOnly")] = collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    collectionDetails[QStringLiteral("canChange")] = collection.rights().testFlag(Akonadi::Collection::CanChangeCollection);
    collectionDetails[QStringLiteral("canCreate")] = collection.rights().testFlag(Akonadi::Collection::CanCreateCollection);
    collectionDetails[QStringLiteral("canDelete")] =
        collection.rights().testFlag(Akonadi::Collection::CanDeleteCollection) && !Akonadi::CollectionUtils::isResource(collection);

    return collectionDetails;
}

void ContactManager::setCollectionColor(Akonadi::Collection collection, const QColor &color)
{
    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);
    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [this, collection, color](KJob *job) {
        if (job->error()) {
            qCWarning(MERKURO_CONTACT_LOG) << "Error occurred modifying collection color: " << job->errorString();
        } else {
            m_repository->setCollectionColor(collection.id(), color);
        }
    });
}

#include "moc_contactmanager.cpp"
