/*
  SPDX-FileCopyrightText: 1998 Barry D Benowitz <b.benowitz@telesciences.com>
  SPDX-FileCopyrightText: 2001 Cornelius Schumacher <schumacher@kde.org>
  SPDX-FileCopyrightText: 2009 Allen Winter <winter@kde.org>
  SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>

  SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include "mailheadermodel.h"
#include <KMime/KMimeMessage>
#include <QObject>

namespace KIdentityManagementCore
{
class Identity;
class IdentityModel;
}

namespace Kleo
{
class KeyResolver;
}

namespace MessageComposer
{
class Composer;
class ContactPreference;
}

namespace MailTransport
{
class Transport;
}

namespace GpgME
{
class Key;
}

class KJob;

namespace Akonadi
{

class MailClient : public QObject
{
    Q_OBJECT

    struct MessageData {
        QString from;
        QStringList to;
        QStringList cc;
        QStringList bcc;
        QString subject;
        QString body;
    };

public:
    enum Result { ResultSuccess, ResultNoAttendees, ResultReallyNoAttendees, ResultErrorCreatingTransport, ResultErrorFetchingTransport, ResultQueueJobError };

    explicit MailClient(QObject *parent = nullptr);
    ~MailClient() override;

    Q_INVOKABLE void send(KIdentityManagementCore::IdentityModel *identityModel, MailHeaderModel *header, const QString &subject, const QString &body);

private:
    std::unique_ptr<MessageComposer::Composer>
    populateComposer(const MessageData &msg, KIdentityManagementCore::IdentityModel *identityModel, int *transportId);

    void queueMessage(const int transport,
                      const MessageComposer::Composer *composer,
                      const KIdentityManagementCore::Identity &identity,
                      const KMime::Message::Ptr &message);

    void handleQueueJobFinished(KJob *job);
    QVector<QByteArray> m_charsets;

Q_SIGNALS:
    void finished(Akonadi::MailClient::Result result, const QString &errorString);
};
}

Q_DECLARE_METATYPE(Akonadi::MailClient::Result)