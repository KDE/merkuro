// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "avatarimageprovider.h"
#include "contactimageprovider.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KContacts/Addressee>
#include <QCoreApplication>

using namespace Qt::Literals::StringLiterals;

AvatarImageProvider *AvatarImageProvider::create(QQmlEngine *engine, QJSEngine *)
{
    const auto instance = new AvatarImageProvider();

    QQmlEngine::setObjectOwnership(instance, QQmlEngine::CppOwnership);

    engine->addImageProvider(u"avatar"_s, instance);
    engine->addImageProvider(u"contact"_s, new ContactImageProvider);
    return instance;
}

QQuickImageResponse *AvatarImageProvider::requestImageResponse(const QString &id, const QSize &)
{
    return new AvatarResponse(id);
}

AvatarResponse::AvatarResponse(const QString &itemId)
{
    moveToThread(QCoreApplication::instance()->thread());
    QMetaObject::invokeMethod(
        this,
        [this, itemId]() {
            auto job = new Akonadi::ItemFetchJob(Akonadi::Item(itemId.toLongLong()), this);
            job->fetchScope().fetchFullPayload();
            connect(job, &KJob::result, this, [this, job]() {
                const auto items = job->items();
                if (!job->error() && !items.isEmpty() && items.first().hasPayload<KContacts::Addressee>()) {
                    const auto photo = items.first().payload<KContacts::Addressee>().photo();
                    if (photo.isIntern()) {
                        m_image = photo.data();
                    }
                }
                Q_EMIT finished();
            });
        },
        Qt::QueuedConnection);
}

QQuickTextureFactory *AvatarResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

#include "moc_avatarimageprovider.cpp"
