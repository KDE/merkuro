// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "attachmentmodel.h"

#include <QFile>
#include <QUrl>

AttachmentModel::AttachmentModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

MessageCore::AttachmentPart::List AttachmentModel::attachments() const
{
    return m_attachments;
}

void AttachmentModel::addAttachment(const QUrl &path)
{
    beginInsertRows({}, rowCount(), rowCount());

    MessageCore::AttachmentPart::Ptr part(new MessageCore::AttachmentPart());
    part->setName(path.fileName());
    part->setFileName(path.fileName());
    part->setUrl(path);
    QFile file(path.toLocalFile());
    (void)file.open(QFile::ReadOnly);
    part->setData(file.readAll());
    m_attachments += part;
    endInsertRows();
}

void AttachmentModel::remove(int index)
{
    beginRemoveRows({}, index, index);
    m_attachments.removeAt(index);
    endRemoveRows();
}

QHash<int, QByteArray> AttachmentModel::roleNames() const
{
    return {
        {FileNameRole, "fileName"},
        {UrlRole, "url"},
    };
}

QVariant AttachmentModel::data(const QModelIndex &index, int role) const
{
    if (role == FileNameRole) {
        return m_attachments[index.row()]->fileName();
    }
    if (role == UrlRole) {
        return m_attachments[index.row()]->url();
    }
    return {};
}

int AttachmentModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_attachments.size();
}

#include "moc_attachmentmodel.cpp"
