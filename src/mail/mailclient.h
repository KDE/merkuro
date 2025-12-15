/*
  SPDX-FileCopyrightText: 1998 Barry D Benowitz <b.benowitz@telesciences.com>
  SPDX-FileCopyrightText: 2001 Cornelius Schumacher <schumacher@kde.org>
  SPDX-FileCopyrightText: 2009 Allen Winter <winter@kde.org>
  SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>

  SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include "attachmentmodel.h"
#include "mailheadermodel.h"
#include <KMime/Message>
#include <MessageComposer/ComposerViewBase>
#include <QObject>

namespace KIdentityManagementCore
{
class Identity;
class IdentityModel;
}

namespace MessageComposer
{
class ComposerJob;
}

namespace MailTransport
{
class Transport;
}

class KJob;

namespace Akonadi
{

class MailClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(MailHeaderModel *headerModel READ headerModel CONSTANT)
    Q_PROPERTY(AttachmentModel *attachmentModel READ attachmentModel CONSTANT)

    struct MessageData {
        QString from;
        QStringList to;
        QStringList cc;
        QStringList bcc;
        QString subject;
        QString body;
    };

public:
    enum Result {
        ResultSuccess,
        ResultNoRecipients,
        ResultReallyNoRecipients,
        ResultErrorCreatingTransport,
        ResultErrorFetchingTransport,
        ResultQueueJobError
    };

    explicit MailClient(QObject *parent = nullptr);
    ~MailClient() override;

    [[nodiscard]] MailHeaderModel *headerModel() const;
    [[nodiscard]] AttachmentModel *attachmentModel() const;

    Q_INVOKABLE void send(KIdentityManagementCore::IdentityModel *identityModel, const QString &subject, const QString &body);

private:
    std::unique_ptr<MessageComposer::ComposerJob>
    populateComposer(const MessageData &msg, KIdentityManagementCore::IdentityModel *identityModel, int *transportId);

    void queueMessage(const int transport,
                      const MessageComposer::ComposerJob *composer,
                      const KIdentityManagementCore::Identity &identity,
                      const std::shared_ptr<KMime::Message> &message);

    void handleQueueJobFinished(KJob *job);

    std::unique_ptr<MailHeaderModel> m_headerModel;
    AttachmentModel *m_attachmentModel;

Q_SIGNALS:
    void finished(Akonadi::MailClient::Result result, const QString &errorString);
};
}

Q_DECLARE_METATYPE(Akonadi::MailClient::Result)
