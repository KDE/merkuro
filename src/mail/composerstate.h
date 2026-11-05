// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "attachmentmodel.h"
#include "mailheadermodel.h"

#include <QObject>
#include <QStringList>
#include <qqmlregistration.h>

// Editable state for one composer, independent of MIME generation and delivery.
class ComposerState : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(uint identityUoid READ identityUoid WRITE setIdentityUoid NOTIFY identityUoidChanged)
    Q_PROPERTY(QString subject READ subject WRITE setSubject NOTIFY subjectChanged)
    Q_PROPERTY(QString body READ body WRITE setBody NOTIFY bodyChanged)
    Q_PROPERTY(MailHeaderModel *headerModel READ headerModel CONSTANT)
    Q_PROPERTY(AttachmentModel *attachmentModel READ attachmentModel CONSTANT)

public:
    struct Snapshot {
        uint identityUoid = 0;
        QString subject;
        QString body;
        QStringList to;
        QStringList cc;
        QStringList bcc;
        QStringList replyTo;
        MessageCore::AttachmentPart::List attachments;
    };

    explicit ComposerState(QObject *parent = nullptr);

    [[nodiscard]] uint identityUoid() const;
    void setIdentityUoid(uint identityUoid);
    [[nodiscard]] QString subject() const;
    void setSubject(const QString &subject);
    [[nodiscard]] QString body() const;
    void setBody(const QString &body);
    [[nodiscard]] MailHeaderModel *headerModel() const;
    [[nodiscard]] AttachmentModel *attachmentModel() const;
    [[nodiscard]] Snapshot snapshot() const;

Q_SIGNALS:
    void identityUoidChanged();
    void subjectChanged();
    void bodyChanged();

private:
    uint m_identityUoid = 0;
    QString m_subject;
    QString m_body;
    MailHeaderModel *const m_headerModel;
    AttachmentModel *const m_attachmentModel;
};
