// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/CachePolicy>
#include <Akonadi/Collection>
#include <QObject>
#include <qqmlregistration.h>

class CollectionEditorController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Akonadi::Collection::Id collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QString displayName READ displayName WRITE setDisplayName NOTIFY displayNameChanged)
    Q_PROPERTY(QString iconName READ iconName WRITE setIconName NOTIFY iconNameChanged)
    Q_PROPERTY(Akonadi::CachePolicy cachePolicy READ cachePolicy WRITE setCachePolicy NOTIFY cachePolicyChanged)

public:
    explicit CollectionEditorController(QObject *parent = nullptr);

    [[nodiscard]] Akonadi::Collection::Id collectionId() const;
    void setCollectionId(const Akonadi::Collection::Id &collectionId);

    [[nodiscard]] QString displayName() const;
    void setDisplayName(const QString &displayName);

    [[nodiscard]] QString iconName() const;
    void setIconName(const QString &iconName);

    [[nodiscard]] Akonadi::CachePolicy cachePolicy() const;
    void setCachePolicy(const Akonadi::CachePolicy &cachePolicy);

    Q_INVOKABLE void save();

Q_SIGNALS:
    void collectionIdChanged();
    void displayNameChanged();
    void iconNameChanged();
    void cachePolicyChanged();

private:
    void fetchCollection();

    Akonadi::Collection::Id mId;
    Akonadi::Collection mCollection;

    QString mDisplayName;
    QString mIconName;
    Akonadi::CachePolicy mCachePolicy;
};