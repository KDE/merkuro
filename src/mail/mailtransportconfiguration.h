// SPDX-FileCopyrightText: 2026 Florian Richer <florian.richer@protonmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <qqmlintegration.h>

#include <MailTransport/TransportManager>
#include <MailTransport/TransportModel>
#include <MailTransport/TransportType>

class MailTransportConfiguration : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(MailTransport::TransportModel *transportModel READ transportModel CONSTANT)
    Q_PROPERTY(MailTransport::TransportType::List availableTransportTypes READ availableTransportTypes CONSTANT)

public:
    explicit MailTransportConfiguration(QObject *parent = nullptr);

    [[nodiscard]] MailTransport::TransportModel *transportModel() const;
    [[nodiscard]] MailTransport::TransportType::List availableTransportTypes() const;

    Q_INVOKABLE [[nodiscard]] bool isRemovable(const int transportId);
    Q_INVOKABLE [[nodiscard]] bool isDefault(const int transportId);

public Q_SLOTS:
    void createNew(const int index, const QString &name, const bool makeDefault);
    void edit(const int transportId);
    void remove(const int transportId);
    void rename(const int transportId, const QString &newName);
    void setDefault(const int transportId);

private:
    std::unique_ptr<MailTransport::TransportModel> m_tranportModel;
};
