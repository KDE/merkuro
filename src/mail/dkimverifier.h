// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <MessageCore/DKIMManager>
#include <qqmlregistration.h>

class DkimVerifier : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(std::shared_ptr<KMime::Message> message READ message WRITE setMessage NOTIFY messageChanged)
    Q_PROPERTY(Status status READ status NOTIFY resultChanged)
    Q_PROPERTY(QString signingDomain READ signingDomain NOTIFY resultChanged)
    Q_PROPERTY(bool hasWarning READ hasWarning NOTIFY resultChanged)

public:
    enum Status : uint8_t {
        Unknown = static_cast<uint8_t>(MessageCore::DKIMCheckSignatureJob::DKIMStatus::Unknown),
        Valid = static_cast<uint8_t>(MessageCore::DKIMCheckSignatureJob::DKIMStatus::Valid),
        Invalid = static_cast<uint8_t>(MessageCore::DKIMCheckSignatureJob::DKIMStatus::Invalid),
        EmailNotSigned = static_cast<uint8_t>(MessageCore::DKIMCheckSignatureJob::DKIMStatus::EmailNotSigned),
        NeedToBeSigned = static_cast<uint8_t>(MessageCore::DKIMCheckSignatureJob::DKIMStatus::NeedToBeSigned),
    };
    Q_ENUM(Status)

    explicit DkimVerifier(QObject *parent = nullptr);

    [[nodiscard]] std::shared_ptr<KMime::Message> message() const;
    void setMessage(const std::shared_ptr<KMime::Message> &message);
    [[nodiscard]] Status status() const;
    [[nodiscard]] QString signingDomain() const;
    [[nodiscard]] bool hasWarning() const;

Q_SIGNALS:
    void messageChanged();
    void resultChanged();

private:
    std::shared_ptr<KMime::Message> m_message;
    MessageCore::DKIMManager *m_manager = nullptr;
    MessageCore::DKIMCheckSignatureJob::CheckSignatureResult m_result;
};
