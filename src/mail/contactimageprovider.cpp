// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "contactimageprovider.h"

#include <Akonadi/ContactSearchJob>
#include <KIO/TransferJob>
#include <QApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QDnsLookup>
#include <QFileInfo>
#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QStandardPaths>
#include <QThread>

#include <KLocalizedString>
#include <kjob.h>
#include <qobject.h>

ContactImageProvider::ContactImageProvider()
    : QQuickAsyncImageProvider()
{
    qnam.setRedirectPolicy(QNetworkRequest::NoLessSafeRedirectPolicy);

    qnam.enableStrictTransportSecurityStore(true, QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QLatin1StringView("/hsts/"));
    qnam.setStrictTransportSecurityEnabled(true);

    auto namDiskCache = new QNetworkDiskCache(&qnam);
    namDiskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QLatin1StringView("/nam/"));
    qnam.setCache(namDiskCache);
}

QQuickImageResponse *ContactImageProvider::requestImageResponse(const QString &email, const QSize &requestedSize)
{
    return new ThumbnailResponse(email, requestedSize, &qnam);
}

ThumbnailResponse::ThumbnailResponse(QString email, QSize size, QNetworkAccessManager *qnam)
    : m_email(std::move(email))
    , requestedSize(size)
    , localFile(QStringLiteral("%1/contact_picture_provider/%2.png").arg(QStandardPaths::writableLocation(QStandardPaths::CacheLocation), m_email))
    , m_qnam(qnam)
    , errorStr(QStringLiteral("Image request hasn't started"))
{
    m_email = m_email.trimmed().toLower();
    QImage cachedImage;
    if (cachedImage.load(localFile)) {
        m_image = cachedImage;
        errorStr.clear();
        Q_EMIT finished();
        return;
    }

    // Execute a request on the main thread asynchronously
    moveToThread(QApplication::instance()->thread());
    QMetaObject::invokeMethod(this, &ThumbnailResponse::startRequest, Qt::QueuedConnection);
}

void ThumbnailResponse::startRequest()
{
    job = new Akonadi::ContactSearchJob();
    job->setQuery(Akonadi::ContactSearchJob::Email, m_email, Akonadi::ContactSearchJob::ExactMatch);

    // Runs in the main thread, not QML thread
    Q_ASSERT(QThread::currentThread() == QApplication::instance()->thread());

    // Connect to any possible outcome including abandonment
    // to make sure the QML thread is not left stuck forever.
    connect(job, &Akonadi::ContactSearchJob::finished, this, &ThumbnailResponse::prepareResult);
}

bool ThumbnailResponse::searchPhoto(const KContacts::AddresseeList &list)
{
    bool foundPhoto = false;
    for (const KContacts::Addressee &addressee : list) {
        const KContacts::Picture photo = addressee.photo();
        if (!photo.isEmpty()) {
            m_photo = photo;
            foundPhoto = true;
            break;
        }
    }
    return foundPhoto;
}

void ThumbnailResponse::prepareResult()
{
    Q_ASSERT(QThread::currentThread() == job->thread());
    auto searchJob = static_cast<Akonadi::ContactSearchJob *>(job);
    {
        QWriteLocker _(&lock);
        if (job->error() == KJob::NoError) {
            bool ok = false;
            const int contactSize(searchJob->contacts().size());
            if (contactSize >= 1) {
                if (contactSize > 1) {
                    qWarning() << " more than 1 contact was found we return first contact";
                }

                const KContacts::Addressee addressee = searchJob->contacts().at(0);
                if (searchPhoto(searchJob->contacts())) {
                    // We have a data raw => we can update message
                    if (m_photo.isIntern()) {
                        m_image = m_photo.data();
                        ok = true;
                    } else {
                        const QUrl url = QUrl::fromUserInput(m_photo.url(), QString(), QUrl::AssumeLocalFile);
                        if (!url.isEmpty()) {
                            if (url.isLocalFile()) {
                                if (m_image.load(url.toLocalFile())) {
                                    ok = true;
                                }
                            } else {
                                QByteArray imageData;
                                KIO::TransferJob *jobTransfert = KIO::get(url, KIO::NoReload);
                                QObject::connect(jobTransfert, &KIO::TransferJob::data, this, [&imageData](KIO::Job *, const QByteArray &data) {
                                    imageData.append(data);
                                });
                                if (jobTransfert->exec()) {
                                    if (m_image.loadFromData(imageData)) {
                                        ok = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            QString localPath = QFileInfo(localFile).absolutePath();
            QDir dir;
            if (!dir.exists(localPath)) {
                dir.mkpath(localPath);
            }

            m_image.save(localFile);

            if (ok) {
                errorStr.clear();
                Q_EMIT finished();
                return;
            } else {
                errorStr = QStringLiteral("No image found");
            }
        } else if (job->error() == Akonadi::Job::UserCanceled) {
            errorStr = i18n("Image request has been cancelled");
        } else {
            errorStr = job->errorString();
        }

        // No image found in Akonadi, try libravatar
        auto dns = new QDnsLookup(this);
        connect(dns, &QDnsLookup::finished, this, [this, dns]() {
            dnsLookupFinished(dns);
        });
        const auto split = m_email.split(QLatin1Char('@'));
        if (split.length() < 2) {
            Q_EMIT finished();
            return;
        }
        const auto domain = split[1];

        dns->setType(QDnsLookup::SRV);
        dns->setName(QStringLiteral("_avatars._tcp.") + domain);
        dns->lookup();
        job = nullptr;
    }
}

void ThumbnailResponse::dnsLookupFinished(QDnsLookup *dns)
{
    if (dns->error() != QDnsLookup::NoError) {
        queryImage();
        dns->deleteLater();
        return;
    }

    const auto records = dns->serviceRecords();
    if (records.count() < 1) {
        queryImage();
        dns->deleteLater();
        return;
    }

    const auto record = records[0];

    QString hostname = record.target();
    if (hostname.endsWith(QLatin1Char('.'))) {
        hostname.chop(1);
    }

    if (record.port() == 443) {
        queryImage(QStringLiteral("https://") + hostname + QStringLiteral("/avatar/"));
    } else {
        queryImage(QStringLiteral("http://") + hostname + QLatin1Char(':') + QString::number(record.port()) + QStringLiteral("/avatar/"));
    }

    dns->deleteLater();
}

void ThumbnailResponse::queryImage(const QString &hostname)
{
    QCryptographicHash hash(QCryptographicHash::Md5);
    hash.addData(m_email.toUtf8());

    const QUrl url(hostname + QString::fromUtf8(hash.result().toHex()) + QStringLiteral("?d=404"));

    QByteArray imageData;
    auto reply = m_qnam->get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        imageQueried(reply);
    });
}

void ThumbnailResponse::imageQueried(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        Q_EMIT finished();
        return;
    }

    const QByteArray imageData = reply->readAll();
    if (m_image.loadFromData(imageData)) {
        QString localPath = QFileInfo(localFile).absolutePath();
        QDir dir;
        if (!dir.exists(localPath)) {
            dir.mkpath(localPath);
        }

        m_image.save(localFile);
    }

    Q_EMIT finished();
}

void ThumbnailResponse::doCancel()
{
    // Runs in the main thread, not QML thread
    if (job) {
        Q_ASSERT(QThread::currentThread() == job->thread());
        job->kill();
    }
}

QQuickTextureFactory *ThumbnailResponse::textureFactory() const
{
    QReadLocker _(&lock);
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

QString ThumbnailResponse::errorString() const
{
    QReadLocker _(&lock);
    return errorStr;
}

void ThumbnailResponse::cancel()
{
    QMetaObject::invokeMethod(this, &ThumbnailResponse::doCancel, Qt::QueuedConnection);
}

#include "moc_contactimageprovider.cpp"
