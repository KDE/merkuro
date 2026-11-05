// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "invitationresponsejob.h"

#include <Akonadi/AddressAttribute>
#include <Akonadi/Collection>
#include <Akonadi/DispatchModeAttribute>
#include <Akonadi/ITIPHandler>
#include <Akonadi/MessageQueueJob>
#include <Akonadi/SentBehaviourAttribute>
#include <Akonadi/TransportAttribute>
#include <KCalendarCore/ICalFormat>
#include <KEmailAddress>
#include <KIdentityManagementCore/IdentityManager>
#include <KLocalizedString>
#include <MailTransport/Transport>
#include <MailTransport/TransportManager>

using namespace Qt::StringLiterals;

InvitationResponseJob::InvitationResponseJob(const KCalendarCore::ScheduleMessage::Ptr &schedule,
                                             const KCalendarCore::Event::Ptr &reply,
                                             const QString &receiver,
                                             bool accept,
                                             QObject *parent)
    : KJob(parent)
    , m_reply(reply)
    , m_receiver(receiver)
    , m_accept(accept)
    , m_identity(KIdentityManagementCore::IdentityManager::self()->identityForAddress(receiver))
{
    // The scheduler can change the incidence UID when storing it. Keep the reply's original scheduling UID.
    auto event = KCalendarCore::IncidenceBase::Ptr(schedule->event().staticCast<KCalendarCore::Event>()->clone());
    m_schedule = KCalendarCore::ScheduleMessage::Ptr::create(event, schedule->method(), schedule->status());
}

void InvitationResponseJob::start()
{
    if (m_identity.isNull()) {
        fail(i18n("The mail identity for %1 is no longer available.", m_receiver));
        return;
    }
    const auto manager = MailTransport::TransportManager::self();
    m_transportId = m_identity.transport().isEmpty() ? manager->defaultTransportId() : m_identity.transport().toInt();
    if (!manager->transportById(m_transportId, false)) {
        fail(i18n("Configure an outgoing mail account before responding to this invitation."));
        return;
    }

    auto handler = new Akonadi::ITIPHandler(this);
    handler->setShowDialogsOnError(false);
    connect(
        handler,
        &Akonadi::ITIPHandler::iTipMessageProcessed,
        this,
        [this](Akonadi::ITIPHandler::Result result, const QString &error) {
            if (result == Akonadi::ITIPHandler::ResultCancelled) {
                setError(KJob::KilledJobError);
                emitResult();
            } else if (result == Akonadi::ITIPHandler::ResultError) {
                fail(error.isEmpty() ? i18n("Could not update the calendar for this invitation.") : error);
            } else {
                queueReply();
            }
        },
        Qt::QueuedConnection);
    // This is the same mapping used by the KMail invitation formatter: declining removes an existing invitation.
    handler->processiTIPMessage(m_receiver, m_schedule, m_accept ? u"accepted"_s : u"cancel"_s);
}

void InvitationResponseJob::queueReply()
{
    const auto transport = MailTransport::TransportManager::self()->transportById(m_transportId, false);
    if (!transport) {
        fail(i18n("The outgoing mail account is no longer available. The calendar was updated, but no response was queued."));
        return;
    }

    KCalendarCore::ICalFormat format;
    const auto calendar = format.createScheduleMessage(m_reply, KCalendarCore::iTIPReply);
    auto message = std::make_shared<KMime::Message>();
    message->from()->fromUnicodeString(KCalendarCore::Person(m_identity.fullName(), m_receiver).fullName());
    message->to()->fromUnicodeString(m_reply->organizer().fullName());
    message->subject()->fromUnicodeString(m_accept ? i18n("Accepted: %1", m_reply->summary()) : i18n("Declined: %1", m_reply->summary()));
    message->date()->setDateTime(QDateTime::currentDateTime());
    message->messageID()->generate(m_receiver.section(u'@', -1).toLatin1());
    message->header<KMime::Headers::MIMEVersion>()->from7BitString("1.0");
    message->contentType()->setMimeType("text/calendar");
    message->contentType()->setCharset("utf-8");
    message->contentType()->setParameter("method", u"REPLY"_s);
    message->contentTransferEncoding()->setEncoding(KMime::Headers::CEquPr);
    message->setBody(KMime::CRLFtoLF(calendar.toUtf8()));
    message->assemble();

    auto queue = new Akonadi::MessageQueueJob(this);
    queue->setMessage(message);
    queue->transportAttribute().setTransportId(m_transportId);
    const auto sender = transport->specifySenderOverwriteAddress() ? transport->senderOverwriteAddress() : m_receiver;
    queue->addressAttribute().setFrom(KEmailAddress::extractEmailAddress(KEmailAddress::normalizeAddressesAndEncodeIdn(sender)));
    queue->addressAttribute().setTo({KEmailAddress::extractEmailAddress(KEmailAddress::normalizeAddressesAndEncodeIdn(m_reply->organizer().email()))});
    queue->dispatchModeAttribute().setDispatchMode(Akonadi::DispatchModeAttribute::Automatic);
    if (m_identity.disabledFcc()) {
        queue->sentBehaviourAttribute().setSentBehaviour(Akonadi::SentBehaviourAttribute::Delete);
    } else {
        const Akonadi::Collection sentCollection(m_identity.fcc().toLongLong());
        queue->sentBehaviourAttribute().setSentBehaviour(sentCollection.isValid() ? Akonadi::SentBehaviourAttribute::MoveToCollection
                                                                                  : Akonadi::SentBehaviourAttribute::MoveToDefaultSentCollection);
        if (sentCollection.isValid()) {
            queue->sentBehaviourAttribute().setMoveToCollection(sentCollection);
        }
    }
    connect(queue, &KJob::result, this, [this](KJob *job) {
        if (job->error()) {
            fail(i18n("The calendar was updated, but the response could not be queued: %1", job->errorText()));
        } else {
            emitResult();
        }
    });
    queue->start();
}

void InvitationResponseJob::fail(const QString &message)
{
    setError(KJob::UserDefinedError);
    setErrorText(message);
    emitResult();
}

#include "moc_invitationresponsejob.cpp"
