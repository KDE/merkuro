// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractListModel>
#include <QList>
#include <qqmlintegration.h>

class TimeZoneListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1
    };
    Q_ENUM(Roles)

    explicit TimeZoneListModel(QObject *parent = nullptr);
    ~TimeZoneListModel() override = default;

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE int getTimeZoneRow(const QByteArray &timeZone);

private:
    QList<QByteArray> m_timeZones;
};
