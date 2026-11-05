// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../mailclient.h"

#include <KIdentityManagementCore/Identity>
#include <KIdentityManagementCore/IdentityManager>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QTest>

using namespace KIdentityManagementCore;
using namespace Qt::Literals::StringLiterals;

class MailClientSignatureTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        QStandardPaths::setTestModeEnabled(true);
    }

    void signature_data()
    {
        QTest::addColumn<QString>("text");
        QTest::addColumn<bool>("enabled");
        QTest::addColumn<bool>("html");
        QTest::addColumn<QString>("expected");
        QTest::newRow("disabled") << u"Alice"_s << false << false << QString();
        QTest::newRow("empty") << QString() << true << false << QString();
        QTest::newRow("plain") << u"Regards,\nAlice"_s << true << false << u"-- \nRegards,\nAlice"_s;
        QTest::newRow("existing-separator") << u"-- \nAlice"_s << true << false << u"-- \nAlice"_s;
        QTest::newRow("html") << u"<p>Regards,<br>Alice</p>"_s << true << true << u"-- \nRegards,\nAlice"_s;
    }

    void signature()
    {
        QFETCH(QString, text);
        QFETCH(bool, enabled);
        QFETCH(bool, html);
        QFETCH(QString, expected);

        auto manager = IdentityManager::self();
        auto identity = manager->newFromScratch(u"Composer signature test"_s);
        Signature signature(text);
        signature.setEnabledSignature(enabled);
        signature.setInlinedHtml(html);
        identity.setSignature(signature);
        manager->saveIdentity(identity);

        Akonadi::MailClient client;
        QCOMPARE(client.signature(identity.uoid()), expected);
        QVERIFY(manager->removeIdentity(identity.identityName()));
        manager->commit();
    }

    void fileSignature()
    {
        QTemporaryFile file;
        QVERIFY(file.open());
        file.write("File signature");
        file.flush();

        auto manager = IdentityManager::self();
        auto identity = manager->newFromScratch(u"File signature test"_s);
        Signature signature(file.fileName(), false);
        signature.setEnabledSignature(true);
        identity.setSignature(signature);
        manager->saveIdentity(identity);

        Akonadi::MailClient client;
        QCOMPARE(client.signature(identity.uoid()), u"-- \nFile signature"_s);
        file.remove();
        QVERIFY(client.signature(identity.uoid()).isEmpty());
        QVERIFY(manager->removeIdentity(identity.identityName()));
        manager->commit();
    }
};

QTEST_MAIN(MailClientSignatureTest)
#include "mailclientsignaturetest.moc"
