// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QQuickAsyncImageProvider>

#include <KContacts/Addressee>
#include <QNetworkAccessManager>
#include <QReadWriteLock>

namespace Akonadi
{
class ContactSearchJob;
}
class QDnsLookup;
class QNetworkReply;

class ThumbnailResponse : public QQuickImageResponse
{
    Q_OBJECT
public:
    ThumbnailResponse(QString mediaId, QSize requestedSize, QNetworkAccessManager *qnam);
    ~ThumbnailResponse() override = default;

private Q_SLOTS:
    void startRequest();
    void prepareResult();
    void doCancel();

private:
    bool searchPhoto(const KContacts::AddresseeList &list);
    void queryImage(const QString &hostame = QStringLiteral("https://seccdn.libravatar.org/avatar/"));
    void imageQueried(QNetworkReply *reply);
    void dnsLookupFinished(QDnsLookup *dns);
    QString m_email;
    QSize requestedSize;
    const QString localFile;
    QNetworkAccessManager *m_qnam;

    QImage m_image;
    KContacts::Picture m_photo;
    QString errorStr;
    Akonadi::ContactSearchJob *job = nullptr;
    mutable QReadWriteLock lock; // Guards ONLY these two members above

    QQuickTextureFactory *textureFactory() const override;
    QString errorString() const override;
    void cancel() override;
};

class ContactImageProvider : public QQuickAsyncImageProvider
{
public:
    explicit ContactImageProvider();
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

private:
    QNetworkAccessManager qnam;
};
