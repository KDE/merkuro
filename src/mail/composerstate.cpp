// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "composerstate.h"

ComposerState::ComposerState(QObject *parent)
    : QObject(parent)
    , m_headerModel(new MailHeaderModel(this))
    , m_attachmentModel(new AttachmentModel(this))
{
}

uint ComposerState::identityUoid() const
{
    return m_identityUoid;
}

void ComposerState::setIdentityUoid(uint identityUoid)
{
    if (m_identityUoid == identityUoid) {
        return;
    }
    m_identityUoid = identityUoid;
    Q_EMIT identityUoidChanged();
}

QString ComposerState::subject() const
{
    return m_subject;
}

void ComposerState::setSubject(const QString &subject)
{
    if (m_subject == subject) {
        return;
    }
    m_subject = subject;
    Q_EMIT subjectChanged();
}

QString ComposerState::body() const
{
    return m_body;
}

void ComposerState::setBody(const QString &body)
{
    if (m_body == body) {
        return;
    }
    m_body = body;
    Q_EMIT bodyChanged();
}

MailHeaderModel *ComposerState::headerModel() const
{
    return m_headerModel;
}

AttachmentModel *ComposerState::attachmentModel() const
{
    return m_attachmentModel;
}

ComposerState::Snapshot ComposerState::snapshot() const
{
    Snapshot result;
    result.identityUoid = m_identityUoid;
    result.subject = m_subject;
    result.body = m_body;
    result.attachments = m_attachmentModel->attachments();
    for (int row = 0; row < m_headerModel->rowCount(); ++row) {
        const auto index = m_headerModel->index(row, 0);
        const auto address = index.data(MailHeaderModel::ValueRole).toString().trimmed();
        if (address.isEmpty()) {
            continue;
        }
        switch (index.data(MailHeaderModel::TypeRole).value<MailHeaderModel::Header>()) {
        case MailHeaderModel::To:
            result.to.append(address);
            break;
        case MailHeaderModel::CC:
            result.cc.append(address);
            break;
        case MailHeaderModel::BCC:
            result.bcc.append(address);
            break;
        case MailHeaderModel::ReplyTo:
            result.replyTo.append(address);
            break;
        case MailHeaderModel::From:
            break;
        }
    }
    return result;
}

#include "moc_composerstate.cpp"
