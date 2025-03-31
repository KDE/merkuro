// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "collectionutils.h"

#include <Akonadi/Collection>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/SpecialMailCollections>

using namespace Akonadi;

bool CollectionUtils::isRemovable(const QModelIndex &collectionId) const
{
    auto collection = collectionId.data(EntityTreeModel::CollectionRole).value<Akonadi::Collection>();

    auto isSystemFolder = (collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Inbox)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Outbox)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::SentMail)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Trash)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Drafts)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Templates)
                           || collection == SpecialMailCollections::self()->defaultCollection(SpecialMailCollections::Spam));
    return (collection.rights() & Akonadi::Collection::CanDeleteItem) && !isSystemFolder;
}

#include "moc_collectionutils.cpp"
