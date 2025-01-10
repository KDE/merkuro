/*
  SPDX-FileCopyrightText: 1998 Barry D Benowitz <b.benowitz@telesciences.com>
  SPDX-FileCopyrightText: 2001 Cornelius Schumacher <schumacher@kde.org>
  SPDX-FileCopyrightText: 2009 Allen Winter <winter@kde.org>
  SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>

  SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "mailclient.h"
#include "../config-merkuro.h"
#include "merkuro_mail_debug.h"

#include <KEmailAddress>
#include <KIdentityManagementCore/Identity>
#include <KIdentityManagementCore/IdentityModel>

#include <Akonadi/MessageQueueJob>
#include <MailTransport/Transport>
#include <MailTransport/TransportManager>

#include <KMime/Headers>

#include <MessageComposer/Composer>
#include <MessageComposer/GlobalPart>
#include <MessageComposer/InfoPart>
#include <MessageComposer/ItipPart>
#include <MessageComposer/TextPart>
#include <MessageComposer/Util>

#include <KJob>
#include <KLocalizedString>

using namespace Akonadi;

MailClient::MailClient(QObject *parent)
    : QObject(parent)
    , m_headerModel(std::make_unique<MailHeaderModel>())
{
}

MailClient::~MailClient() = default;

void MailClient::send(KIdentityManagementCore::IdentityModel *identityModel, const QString &subject, const QString &body)
{
    if (!m_headerModel->rowCount()) {
        qCWarning(MERKURO_MAIL_LOG) << "There are no recipients to e-mail";
        Q_EMIT finished(ResultNoRecipients, i18n("There are no recipients to e-mail"));
        return;
    }

    MessageData msg;
    msg.from = identityModel->data(identityModel->index(0, 0), KIdentityManagementCore::IdentityModel::EmailRole).toString();
    msg.subject = subject;
    msg.body = body;

    const int numberOfRecipients = m_headerModel->rowCount();
    for (int recipient = 0; recipient < numberOfRecipients; recipient++) {
        const auto email = m_headerModel->data(m_headerModel->index(recipient, 0), MailHeaderModel::ValueRole).toString();
        const auto headerRecipient = m_headerModel->data(m_headerModel->index(recipient, 0), MailHeaderModel::TypeRole).value<MailHeaderModel::Header>();
        if (email.isEmpty()) {
            continue;
        } else if (headerRecipient == MailHeaderModel::To) {
            msg.to.push_back(email);
        } else if (headerRecipient == MailHeaderModel::CC) {
            msg.cc.push_back(email);
        } else if (headerRecipient == MailHeaderModel::BCC) {
            msg.bcc.push_back(email);
        }
    }

    if (msg.cc.isEmpty() && msg.to.isEmpty() && msg.bcc.isEmpty()) {
        qCWarning(MERKURO_MAIL_LOG) << "There are really no recipients to e-mail";
        Q_EMIT finished(ResultReallyNoRecipients, i18n("There are no recipients to e-mail"));
        return;
    }

    const auto uoid = identityModel->data(identityModel->index(0, 0), KIdentityManagementCore::IdentityModel::UoidRole).toInt();
    const auto identity = KIdentityManagementCore::IdentityManager::self()->identityForUoid(uoid);
    const auto transportMgr = MailTransport::TransportManager::self();
    int transportId = -1;
    if (!identity.transport().isEmpty()) {
        transportId = identity.transport().toInt();
    } else {
        qWarning(MERKURO_MAIL_LOG) << "Error while loading transport, using default tranport instead";
        transportId = transportMgr->defaultTransportId();
    }

    // No transport exits ask user to create one
    if (transportId == -1) {
        if (!transportMgr->showTransportCreationDialog(nullptr, MailTransport::TransportManager::IfNoTransportExists)) {
            qCritical() << "Error creating transport";
            Q_EMIT finished(ResultErrorCreatingTransport, i18n("Error creating transport"));
        }
        transportId = transportMgr->defaultTransportId();
    }

    auto composerPtr = populateComposer(msg, identityModel, &transportId);
    auto *composer = composerPtr.release();
    QObject::connect(composer, &MessageComposer::Composer::result, this, [this, transportId, composer, identity, msg]() {
        for (const auto &message : composer->resultMessages()) {
            queueMessage(transportId, composer, identity, message);
        }
        composer->deleteLater();
    });
    composer->start();
}

std::unique_ptr<MessageComposer::Composer>
MailClient::populateComposer(const MessageData &msg, KIdentityManagementCore::IdentityModel *identityModel, int *transportId)
{
    auto composer = std::make_unique<MessageComposer::Composer>();
    auto *globalPart = composer->globalPart();
    globalPart->setGuiEnabled(false);
    globalPart->setMDNRequested(false);
    globalPart->setRequestDeleveryConfirmation(false);

    auto *infoPart = composer->infoPart();
    infoPart->setCc(msg.cc);
    infoPart->setTo(msg.to);
    infoPart->setFrom(msg.from);
    infoPart->setBcc(msg.bcc);
    infoPart->setSubject(msg.subject);
    infoPart->setTransportId(*transportId);
    infoPart->setUrgent(true);
    infoPart->setUserAgent(QStringLiteral("Merkuro-Mail"));

    // Setting Headers
    KMime::Headers::Base::List extras;

    auto *header = new KMime::Headers::Generic("X-Merkuro-Mail-Transport");
    header->fromUnicodeString(QString::number(*transportId));
    extras.push_back(header);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Transport-Name");
    auto transportName = identityModel->data(identityModel->index(0, 0), KIdentityManagementCore::IdentityModel::DisplayNameRole).toString();
    header->fromUnicodeString(transportName);
    infoPart->setExtraHeaders(extras);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Identity");
    auto identity = identityModel->data(identityModel->index(0, 0), KIdentityManagementCore::IdentityModel::UoidRole).toString();
    header->fromUnicodeString(identity);
    infoPart->setExtraHeaders(extras);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Identity-Name");
    auto identityName = identityModel->data(identityModel->index(0, 0), KIdentityManagementCore::IdentityModel::IdentityNameRole).toString();
    header->fromUnicodeString(identityName);
    infoPart->setExtraHeaders(extras);

    // Setting Message Body
    auto *textPart = composer->textPart();
    textPart->setCleanPlainText(msg.body);
    textPart->setWordWrappingEnabled(false);

    return composer;
}

void MailClient::queueMessage(const int transportId,
                              const MessageComposer::Composer *composer,
                              const KIdentityManagementCore::Identity &identity,
                              const KMime::Message::Ptr &message)
{
    Akonadi::MessageQueueJob *qjob = new Akonadi::MessageQueueJob(this);
    message->assemble();
    qjob->setMessage(message);

    if (identity.disabledFcc()) {
        qjob->sentBehaviourAttribute().setSentBehaviour(Akonadi::SentBehaviourAttribute::Delete);
    } else {
        const Akonadi::Collection sentCollection(identity.fcc().toLongLong());
        if (sentCollection.isValid()) {
            qjob->sentBehaviourAttribute().setSentBehaviour(Akonadi::SentBehaviourAttribute::MoveToCollection);
            qjob->sentBehaviourAttribute().setMoveToCollection(sentCollection);
        } else {
            qjob->sentBehaviourAttribute().setSentBehaviour(Akonadi::SentBehaviourAttribute::MoveToDefaultSentCollection);
        }
    }

    qjob->transportAttribute().setTransportId(transportId);
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (transport && transport->specifySenderOverwriteAddress()) {
        qjob->addressAttribute().setFrom(
            KEmailAddress::extractEmailAddress(KEmailAddress::normalizeAddressesAndEncodeIdn(transport->senderOverwriteAddress())));
    } else if (!transport) {
        qCritical() << "Error loading transport";
        Q_EMIT finished(ResultErrorFetchingTransport, i18n("Error loading transport"));
    } else {
        qjob->addressAttribute().setFrom(KEmailAddress::extractEmailAddress(KEmailAddress::normalizeAddressesAndEncodeIdn(composer->infoPart()->from())));
    }

    qjob->addressAttribute().setTo(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->to()));
    qjob->addressAttribute().setCc(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->cc()));
    qjob->addressAttribute().setBcc(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->bcc()));

    connect(qjob, &KJob::finished, this, &MailClient::handleQueueJobFinished);
    qjob->start();
}

void MailClient::handleQueueJobFinished(KJob *job)
{
    if (job->error()) {
        qCritical() << "Error queueing message:" << job->errorText();
        Q_EMIT finished(ResultQueueJobError, i18n("Error queuing message in outbox: %1", job->errorText()));
    } else {
        Q_EMIT finished(ResultSuccess, QString());
    }
}

MailHeaderModel *MailClient::headerModel() const
{
    return m_headerModel.get();
}

#include "moc_mailclient.cpp"
