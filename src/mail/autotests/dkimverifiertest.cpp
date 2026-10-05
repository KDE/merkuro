// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "../dkimverifier.h"
#include <QSignalSpy>
#include <QTest>

using Status = DkimVerifier::Status;

class DkimVerifierTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void verify_data()
    {
        QTest::addColumn<QByteArray>("headers");
        QTest::addColumn<Status>("status");
        QTest::newRow("unsigned") << QByteArray() << Status::EmailNotSigned;
        QTest::newRow("malformed-signature") << QByteArray("DKIM-Signature: invalid\n") << Status::Invalid;
    }

    void verify()
    {
        QFETCH(QByteArray, headers);
        QFETCH(Status, status);
        auto message = std::make_shared<KMime::Message>();
        message->setContent(headers + "From: sender@example.org\nTo: recipient@example.org\nSubject: Test\n\nBody\n");
        message->parse();

        DkimVerifier verifier;
        QSignalSpy messageSpy(&verifier, &DkimVerifier::messageChanged);
        QSignalSpy resultSpy(&verifier, &DkimVerifier::resultChanged);
        QCOMPARE(verifier.status(), Status::Unknown);
        verifier.setMessage(message);
        QTRY_COMPARE(verifier.status(), status);
        QCOMPARE(messageSpy.count(), 1);
        QVERIFY(resultSpy.count() >= 2);

        verifier.setMessage(message);
        QCOMPARE(messageSpy.count(), 1);
        verifier.setMessage({});
        QCOMPARE(verifier.status(), Status::Unknown);
        QVERIFY(verifier.signingDomain().isEmpty());
        QVERIFY(!verifier.hasWarning());
        QVERIFY(!verifier.message());
    }

    void cancelVerification()
    {
        auto message = std::make_shared<KMime::Message>();
        message->setContent("From: sender@example.org\n\nBody\n");
        message->parse();
        DkimVerifier verifier;
        verifier.setMessage(message);
        verifier.setMessage({});
        QCoreApplication::sendPostedEvents();
        QCoreApplication::processEvents();
        QCOMPARE(verifier.status(), Status::Unknown);
        QVERIFY(!verifier.message());
    }

    void signingDomainAndWarning()
    {
        auto message = std::make_shared<KMime::Message>();
        message->setContent("From: sender@example.org\n\nBody\n");
        message->parse();
        DkimVerifier verifier;
        verifier.setMessage(message);
        auto manager = verifier.findChild<MessageCore::DKIMManager *>();
        QVERIFY(manager);

        MessageCore::DKIMCheckSignatureJob::CheckSignatureResult result;
        result.status = MessageCore::DKIMCheckSignatureJob::DKIMStatus::Valid;
        result.sdid = QStringLiteral("example.org");
        result.warning = MessageCore::DKIMCheckSignatureJob::DKIMWarning::SignatureExpired;
        manager->result(result, -1);
        QCOMPARE(verifier.status(), Status::Valid);
        QCOMPARE(verifier.signingDomain(), QStringLiteral("example.org"));
        QVERIFY(verifier.hasWarning());

        verifier.setMessage({});
        QVERIFY(verifier.signingDomain().isEmpty());
        QVERIFY(!verifier.hasWarning());
    }
};

QTEST_GUILESS_MAIN(DkimVerifierTest)
#include "dkimverifiertest.moc"
