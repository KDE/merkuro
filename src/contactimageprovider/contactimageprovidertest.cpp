// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "contactimageprovider.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QTest>

#include <memory>

using namespace Qt::Literals::StringLiterals;

class ContactImageProviderTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        QVERIFY(m_cacheDirectory.isValid());
        qputenv("XDG_CACHE_HOME", m_cacheDirectory.path().toUtf8());
    }

    void returnsCachedImage()
    {
        QCoreApplication::setApplicationName(u"Merkuro Mail"_s);
        const auto path = ContactImageProvider::cacheFilePath(u"ada@example.org"_s);
        QVERIFY(path.startsWith(m_cacheDirectory.path()));
        QVERIFY(QDir().mkpath(QFileInfo(path).absolutePath()));
        QImage image(4, 4, QImage::Format_ARGB32);
        image.fill(Qt::red);
        QVERIFY(image.save(path));

        QCoreApplication::setApplicationName(u"Merkuro Contact"_s);
        ContactImageProvider provider;
        std::unique_ptr<QQuickImageResponse> response(provider.requestImageResponse(u" ADA@EXAMPLE.ORG "_s, {}));
        QSignalSpy finished(response.get(), &QQuickImageResponse::finished);
        QTRY_COMPARE(finished.count(), 1);
        QCOMPARE(response->errorString(), QString());

        std::unique_ptr<QQuickTextureFactory> texture(response->textureFactory());
        QCOMPARE(texture->image().pixelColor(0, 0), QColor(Qt::red));
    }

    void honorsRecentNegativeCache()
    {
        const auto path = ContactImageProvider::cacheFilePath(u"missing@example.org"_s);
        QVERIFY(QDir().mkpath(QFileInfo(path).absolutePath()));
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        QCOMPARE(file.write("0"), 1);
        file.close();

        ContactImageProvider provider;
        std::unique_ptr<QQuickImageResponse> response(provider.requestImageResponse(u"missing@example.org"_s, {}));
        QSignalSpy finished(response.get(), &QQuickImageResponse::finished);
        QTRY_COMPARE(finished.count(), 1);
        QVERIFY(!response->errorString().isEmpty());
    }

private:
    QTemporaryDir m_cacheDirectory;
};

QTEST_MAIN(ContactImageProviderTest)

#include "contactimageprovidertest.moc"
