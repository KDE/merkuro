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

#include <MailTransport/Transport>
#include <MailTransport/TransportManager>

#include <KMime/Headers>

#include <MessageComposer/AttachmentControllerBase>
#include <MessageComposer/AttachmentModel>
#include <MessageComposer/ComposerJob>
#include <MessageComposer/GlobalPart>
#include <MessageComposer/InfoPart>
#include <MessageComposer/ItipPart>
#include <MessageComposer/TextPart>
#include <MessageComposer/Util>

#include <KJob>
#include <KLocalizedString>
#include <messagecore/attachmentpart.h>

using namespace Akonadi;
using namespace Qt::Literals::StringLiterals;
MailClient::MailClient(QObject *parent)
    : QObject(parent)
    , m_headerModel(std::make_unique<MailHeaderModel>())
    , m_attachmentModel(new AttachmentModel(this))
    , m_deliveryMode(DeliveryMode::Now)
{
}

MailClient::~MailClient() = default;

void MailClient::send(uint uoid, const QString &subject, const QString &body)
{
    if (!m_headerModel->rowCount()) {
        qCWarning(MERKURO_MAIL_LOG) << "There are no recipients to e-mail";
        Q_EMIT finished(ResultNoRecipients, i18n("There are no recipients to e-mail"));
        return;
    }

    auto const &identity = KIdentityManagementCore::IdentityManager::self()->identityForUoid(uoid);

    auto msg = populateMessageData(identity, subject, body);
    if (!msg.has_value()) {
        // Errors emitted by the populateMessageData
        return;
    }

    auto transportId = fetchTransportId(identity);
    if (!transportId.has_value()) {
        qCWarning(MERKURO_MAIL_LOG) << "No transport found";
        Q_EMIT finished(ResultErrorFetchingTransport, i18n("No transport found"));
        return;
    }

    auto composerPtr = populateComposer(msg.value(), identity, &transportId.value());
    auto *composer = composerPtr.release();
    QObject::connect(composer, &MessageComposer::ComposerJob::result, this, [this, transportId, composer, identity, msg]() {
        for (const auto &message : composer->resultMessages()) {
            auto messageQueueJob = prepareMessageQueueJob(transportId.value(), composer, identity, message);
            if (!messageQueueJob.has_value()) {
                return;
            }

            auto deliveryInfoValid = populateMessageQueueJobWithDeliveryInfo(messageQueueJob.value(), m_deliveryMode, m_sendAfter);
            if (!deliveryInfoValid) {
                return;
            }

            messageQueueJob.value()->start();
        }
        composer->deleteLater();
    });
    composer->start();
}

void MailClient::setDeliveryMode(const DeliveryMode mode, const QDateTime &sendAfter)
{
    m_deliveryMode = mode;
    m_sendAfter = sendAfter;
}

std::optional<int> MailClient::fetchTransportId(const KIdentityManagementCore::Identity &identity)
{
    const auto transportMgr = MailTransport::TransportManager::self();

    if (!identity.transport().isEmpty()) {
        return identity.transport().toInt();
    }

    qWarning(MERKURO_MAIL_LOG) << "Error while loading transport, using default transport instead";
    int transportId = transportMgr->defaultTransportId();
    if (transportId != -1) {
        return transportId;
    }

    if (!transportMgr->showTransportCreationDialog(nullptr, MailTransport::TransportManager::IfNoTransportExists)) {
        qCritical() << "Error creating transport";
        Q_EMIT finished(ResultErrorCreatingTransport, i18n("Error creating transport"));
        return std::nullopt;
    }

    // If a bug encountered during creation of the transport and not reported by the dialog
    transportId = transportMgr->defaultTransportId();
    return transportId != -1 ? std::make_optional(transportId) : std::nullopt;
}

std::optional<MailClient::MessageData>
MailClient::populateMessageData(const KIdentityManagementCore::Identity &identity, const QString &subject, const QString &body)
{
    MessageData msg;
    msg.from = identity.primaryEmailAddress();
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
        return std::nullopt;
    }

    return msg;
}

bool MailClient::populateMessageQueueJobWithDeliveryInfo(Akonadi::MessageQueueJob *job, const DeliveryMode mode, const QDateTime &sendAfter)
{
    if (mode == DeliveryMode::Now) {
        return true;
    }

    if (mode == DeliveryMode::Scheduled && !sendAfter.isValid()) {
        qCWarning(MERKURO_MAIL_LOG) << "sendAfter is not valid.";
        Q_EMIT finished(ResultNoSendDate, i18n("Send date is not valid."));
        return false;
    }

    auto dispatchMode = mode == DeliveryMode::Scheduled ? DispatchModeAttribute::Automatic : DispatchModeAttribute::Manual;
    job->dispatchModeAttribute().setDispatchMode(dispatchMode);

    if (sendAfter.isValid()) {
        job->dispatchModeAttribute().setSendAfter(sendAfter);
    }

    return true;
}

std::unique_ptr<MessageComposer::ComposerJob>
MailClient::populateComposer(const MessageData &msg, KIdentityManagementCore::Identity const &identity, int *transportId)
{
    auto composer = std::make_unique<MessageComposer::ComposerJob>();
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
    infoPart->setUserAgent(u"Merkuro-Mail"_s);

    composer->addAttachmentParts(m_attachmentModel->attachments());

    // Setting Headers
    QList<KMime::Headers::Base *> extras;

    auto *header = new KMime::Headers::Generic("X-Merkuro-Mail-Transport");
    header->fromUnicodeString(QString::number(*transportId));
    extras.push_back(header);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Transport-Name");
    // Taken from KIdentityManagement, src/core/identitymodel.cpp
    auto transportName = QString(identity.identityName() + i18nc("Separator between identity name and email address", " — ") + identity.fullEmailAddr());
    header->fromUnicodeString(transportName);
    infoPart->setExtraHeaders(extras);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Identity");
    auto uoid = QString::number(identity.uoid());
    header->fromUnicodeString(uoid);
    infoPart->setExtraHeaders(extras);

    header = new KMime::Headers::Generic("X-Merkuro-Mail-Identity-Name");
    auto identityName = identity.identityName();
    header->fromUnicodeString(identityName);
    infoPart->setExtraHeaders(extras);

    // Setting Message Body
    auto *textPart = composer->textPart();
    textPart->setCleanPlainText(msg.body);
    textPart->setWordWrappingEnabled(false);

    return composer;
}

std::optional<Akonadi::MessageQueueJob *> MailClient::prepareMessageQueueJob(const int transportId,
                                                                             const MessageComposer::ComposerJob *composer,
                                                                             const KIdentityManagementCore::Identity &identity,
                                                                             const std::shared_ptr<KMime::Message> &message)
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
        return std::nullopt;
    } else {
        qjob->addressAttribute().setFrom(KEmailAddress::extractEmailAddress(KEmailAddress::normalizeAddressesAndEncodeIdn(composer->infoPart()->from())));
    }

    qjob->addressAttribute().setTo(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->to()));
    qjob->addressAttribute().setCc(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->cc()));
    qjob->addressAttribute().setBcc(MessageComposer::Util::cleanUpEmailListAndEncoding(composer->infoPart()->bcc()));

    connect(qjob, &KJob::finished, this, &MailClient::handleQueueJobFinished);

    return qjob;
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

AttachmentModel *MailClient::attachmentModel() const
{
    return m_attachmentModel;
}

#include "moc_mailclient.cpp"
