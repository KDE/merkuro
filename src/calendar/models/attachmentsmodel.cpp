// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "attachmentsmodel.h"
#include "merkuro_calendar_debug.h"
#include <QMetaEnum>
using namespace Qt::Literals::StringLiterals;
AttachmentsModel::AttachmentsModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
{
    for (int i = 0; i < QMetaEnum::fromType<AttachmentsModel::Roles>().keyCount(); i++) {
        const int value = QMetaEnum::fromType<AttachmentsModel::Roles>().value(i);
        const QString key = QLatin1StringView(roleNames().value(value));
        m_dataRoles[key] = value;
    }
}

KCalendarCore::Incidence::Ptr AttachmentsModel::incidencePtr()
{
    return m_incidence;
}

void AttachmentsModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    beginResetModel();
    m_incidence = incidence;
    endResetModel();
    Q_EMIT incidencePtrChanged();
    Q_EMIT attachmentsChanged();
}

KCalendarCore::Attachment::List AttachmentsModel::attachments() const
{
    return m_incidence ? m_incidence->attachments() : KCalendarCore::Attachment::List{};
}

QVariantMap AttachmentsModel::dataroles() const
{
    return m_dataRoles;
}

QVariant AttachmentsModel::data(const QModelIndex &idx, int role) const
{
    if (idx.model() != this || !hasIndex(idx.row(), idx.column())) {
        return {};
    }

    KCalendarCore::Attachment attachment = m_incidence->attachments()[idx.row()];
    switch (role) {
    case AttachmentRole:
        return QVariant::fromValue(attachment);
    case LabelRole:
        return attachment.label();
    case MimeTypeRole:
        return attachment.mimeType();
    case IconNameRole: {
        QMimeType type = m_mimeDb.mimeTypeForUrl(QUrl(attachment.uri()));
        return type.iconName();
    }
    case DataRole:
        return attachment.data(); // This is in bytes
    case SizeRole:
        return attachment.size();
    case URIRole:
        return attachment.uri();
    default:
        qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for attachment:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> AttachmentsModel::roleNames() const
{
    return {
        {AttachmentRole, "attachment"_ba},
        {LabelRole, "attachmentLabel"_ba},
        {MimeTypeRole, "mimetype"_ba},
        {IconNameRole, "iconName"_ba},
        {DataRole, "data"_ba},
        {SizeRole, "size"_ba},
        {URIRole, "uri"_ba},
    };
}

int AttachmentsModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() || !m_incidence ? 0 : m_incidence->attachments().size();
}

void AttachmentsModel::addAttachment(const QString &uri)
{
    if (!m_incidence || m_incidence->isReadOnly() || uri.isEmpty()) {
        return;
    }
    const QMimeType type = m_mimeDb.mimeTypeForUrl(QUrl(uri));

    KCalendarCore::Attachment attachment(uri);
    attachment.setLabel(QUrl(uri).fileName());
    attachment.setMimeType(type.name());
    const int row = rowCount();
    beginInsertRows({}, row, row);
    m_incidence->addAttachment(attachment);
    endInsertRows();

    Q_EMIT attachmentsChanged();
}

void AttachmentsModel::deleteAttachment(const QString &uri)
{
    if (!m_incidence || m_incidence->isReadOnly()) {
        return;
    }
    auto attachments = m_incidence->attachments();
    // Remove each matching row separately so indexes for other attachments remain valid.
    for (int row = attachments.size() - 1; row >= 0; --row) {
        if (attachments.at(row).uri() != uri) {
            continue;
        }
        beginRemoveRows({}, row, row);
        attachments.removeAt(row);
        m_incidence->clearAttachments();
        for (const auto &attachment : attachments) {
            m_incidence->addAttachment(attachment);
        }
        endRemoveRows();
        Q_EMIT attachmentsChanged();
    }
}

#include "moc_attachmentsmodel.cpp"
