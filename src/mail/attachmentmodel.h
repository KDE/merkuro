// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <qqmlintegration.h>

#include <MessageCore/AttachmentPart>

class AttachmentModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

public:
    enum RoleNames {
        FileNameRole = Qt::DisplayRole,
        UrlRole,
    };
    Q_ENUM(RoleNames);
    explicit AttachmentModel(QObject *parent);
    MessageCore::AttachmentPart::List attachments() const;

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAttachment(const QUrl &path);
    Q_INVOKABLE void remove(int index);

private:
    MessageCore::AttachmentPart::List m_attachments;
};
