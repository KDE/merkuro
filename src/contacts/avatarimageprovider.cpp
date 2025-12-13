// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "avatarimageprovider.h"
#include "contactmanager.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KContacts/Addressee>

using namespace Qt::Literals::StringLiterals;

AvatarImageProvider *AvatarImageProvider::create(QQmlEngine *engine, QJSEngine *)
{
    auto instance = new AvatarImageProvider();
    engine->addImageProvider(u"avatar"_s, instance);
    return instance;
}

QQuickImageResponse *AvatarImageProvider::requestImageResponse(const QString &id, const QSize &)
{
    return new AvatarResponse(id);
}

AvatarResponse::AvatarResponse(const QString &itemId)
{
    auto item = ContactManager::create(nullptr, nullptr)->getItem(itemId.toInt());
    if (!item.hasPayload<KContacts::Addressee>()) {
        // Payload not found, try to fetch it
        auto job = new Akonadi::ItemFetchJob(item);
        job->fetchScope().fetchFullPayload();
        connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
            auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
            auto item = fetchJob->items().at(0);
            if (item.hasPayload<KContacts::Addressee>()) {
                auto addressee = item.payload<KContacts::Addressee>();
                if (addressee.photo().isIntern()) {
                    m_image = addressee.photo().data();
                    Q_EMIT finished();
                }
            }
        });
    } else {
        auto addressee = item.payload<KContacts::Addressee>();
        if (addressee.photo().isIntern()) {
            m_image = addressee.photo().data();
            Q_EMIT finished();
        }
    }
}

QQuickTextureFactory *AvatarResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}
