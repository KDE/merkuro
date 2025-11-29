// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <QAbstractListModel>
#include <qqmlregistration.h>

class MailHeaderModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        ValueRole = Qt::DisplayRole,
        TypeRole,
    };
    Q_ENUM(Roles)

    enum Header {
        To,
        From,
        BCC,
        CC,
        ReplyTo,
    };
    Q_ENUM(Header)

    explicit MailHeaderModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role) const override;
    Q_INVOKABLE int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void setValue(int row, const QString &value);
    Q_INVOKABLE void setType(int row, const MailHeaderModel::Header type);

    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

private:
    struct HeaderItem {
        Header type;
        QString value;
    };

    QList<HeaderItem> m_headers;
};
