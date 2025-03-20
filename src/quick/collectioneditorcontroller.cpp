// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "collectioneditorcontroller.h"
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/EntityDisplayAttribute>

CollectionEditorController::CollectionEditorController(QObject *parent)
    : QObject(parent)
{
}

Akonadi::Collection::Id CollectionEditorController::collectionId() const
{
    return mId;
}

void CollectionEditorController::setCollectionId(const Akonadi::Collection::Id &collectionId)
{
    if (mId == collectionId) {
        return;
    }
    mId = collectionId;
    mCollection = Akonadi::Collection{};
    Q_EMIT collectionIdChanged();

    fetchCollection();
}

void CollectionEditorController::fetchCollection()
{
    mCollection = Akonadi::Collection{};

    auto job = new Akonadi::CollectionFetchJob(QList<Akonadi::Collection::Id>{mId});
    connect(job, &Akonadi::CollectionFetchJob::finished, this, [this, job](KJob *) {
        if (job->error()) {
            qWarning() << job->errorString();
            return;
        }
        const auto collections = job->collections();
        if (collections.isEmpty() || collections.at(0).id() != mId) {
            return;
        }
        mCollection = collections.at(0);
        setDisplayName(mCollection.displayName());
        setIconName(mCollection.attribute<Akonadi::EntityDisplayAttribute>()->iconName());
        setCachePolicy(mCollection.cachePolicy());
    });
}

Akonadi::CachePolicy CollectionEditorController::cachePolicy() const
{
    return mCachePolicy;
}

void CollectionEditorController::setCachePolicy(const Akonadi::CachePolicy &cachePolicy)
{
    if (mCachePolicy == cachePolicy) {
        return;
    }
    mCachePolicy = cachePolicy;
    Q_EMIT cachePolicyChanged();
}

QString CollectionEditorController::displayName() const
{
    return mDisplayName;
}

void CollectionEditorController::setDisplayName(const QString &displayName)
{
    if (mDisplayName == displayName) {
        return;
    }
    mDisplayName = displayName;
    Q_EMIT displayNameChanged();
}

QString CollectionEditorController::iconName() const
{
    return mIconName;
}

void CollectionEditorController::setIconName(const QString &iconName)
{
    if (mIconName == iconName) {
        return;
    }
    mIconName = iconName;
    Q_EMIT iconNameChanged();
}

void CollectionEditorController::save()
{
    Akonadi::Collection modifiedCollection(mId);

    bool modified = false;
    if (!mCollection.isValid()) {
        return;
    }

    if (mDisplayName != mCollection.displayName() || mIconName != mCollection.attribute<Akonadi::EntityDisplayAttribute>()->iconName()) {
        auto displayAttribute = modifiedCollection.attribute<Akonadi::EntityDisplayAttribute>(Akonadi::Collection::AddIfMissing);
        displayAttribute->setDisplayName(mDisplayName);
        displayAttribute->setIconName(mIconName);

        // TODO add copy constructor to EntityDisplayAttribute
        auto originDisplayAttribute = mCollection.attribute<Akonadi::EntityDisplayAttribute>(Akonadi::Collection::AddIfMissing);
        displayAttribute->setActiveIconName(originDisplayAttribute->activeIconName());
        displayAttribute->setBackgroundColor(originDisplayAttribute->backgroundColor());

        modified = true;
    }

    if (mCachePolicy != mCollection.cachePolicy()) {
        modified = true;
        modifiedCollection.setCachePolicy(mCachePolicy);
    }

    if (modified) {
        auto job = new Akonadi::CollectionModifyJob(modifiedCollection);
        connect(job, &Akonadi::CollectionModifyJob::result, job, [this, job](KJob *) {
            if (job->error()) {
                qWarning() << job->errorString();
            }

            fetchCollection();
        });
    }
}
