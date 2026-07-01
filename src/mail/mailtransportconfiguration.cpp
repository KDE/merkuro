// SPDX-FileCopyrightText: 2026 Florian Richer <florian.richer@protonmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailtransportconfiguration.h"
#include "merkuro_mail_debug.h"
#include <qloggingcategory.h>

MailTransportConfiguration::MailTransportConfiguration(QObject *parent)
    : QObject(parent)
    , m_tranportModel(new MailTransport::TransportModel(this))
{
    m_tranportModel->setShowDefault(true);
}

MailTransport::TransportModel *MailTransportConfiguration::transportModel() const
{
    return m_tranportModel.get();
}

MailTransport::TransportType::List MailTransportConfiguration::availableTransportTypes() const
{
    return MailTransport::TransportManager::self()->types();
}

void MailTransportConfiguration::createNew(const int index, const QString name, const bool setDefault)
{
    const auto transportType = MailTransport::TransportManager::self()->types().at(index);

    if (transportType.isValid()) {
        auto transport = MailTransport::TransportManager::self()->createTransport();
        transport->setName(name);
        transport->setIdentifier(transportType.identifier());
        transport->forceUniqueName();
        MailTransport::TransportManager::self()->initializeTransport(transport->identifier(), transport);

        if (MailTransport::TransportManager::self()->configureTransport(transport->identifier(), transport, nullptr)) {
            MailTransport::TransportManager::self()->addTransport(transport);

            if (setDefault) {
                MailTransport::TransportManager::self()->setDefaultTransport(transport->id());
            }
        }
    }
}

void MailTransportConfiguration::edit(const int transportId)
{
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (!transport) {
        qCWarning(MERKURO_MAIL_LOG) << "edit called with invalid transportId";
        return;
    }

    MailTransport::TransportManager::self()->configureTransport(transport->identifier(), transport, nullptr);
}

void MailTransportConfiguration::remove(const int transportId)
{
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (!transport) {
        qCWarning(MERKURO_MAIL_LOG) << "remove called with invalid transportId";
        return;
    }

    MailTransport::TransportManager::self()->removeTransport(transport->id());
}

bool MailTransportConfiguration::isRemovable(const int transportId)
{
    return !isDefault(transportId);
}

void MailTransportConfiguration::rename(const int transportId, const QString newName)
{
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (!transport) {
        qCWarning(MERKURO_MAIL_LOG) << "remove called with invalid transportId";
        return;
    }

    transport->setName(newName);
    transport->forceUniqueName();
    transport->save();
}

void MailTransportConfiguration::setDefault(const int transportId)
{
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (!transport) {
        qCWarning(MERKURO_MAIL_LOG) << "remove called with invalid transportId";
        return;
    }

    MailTransport::TransportManager::self()->setDefaultTransport(transport->id());
}

bool MailTransportConfiguration::isDefault(const int transportId)
{
    const auto transport = MailTransport::TransportManager::self()->transportById(transportId);
    if (!transport) {
        qCWarning(MERKURO_MAIL_LOG) << "isRemovable called with not valid transportId";
        return true;
    }

    return transport->id() == MailTransport::TransportManager::self()->defaultTransportId();
}

#include "moc_mailtransportconfiguration.cpp"
