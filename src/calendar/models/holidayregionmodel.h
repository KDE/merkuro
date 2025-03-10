// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractListModel>
#include <qqmlregistration.h>

class HolidayRegionModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        RegionCodeRole = Qt::UserRole + 1
    };

    explicit HolidayRegionModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QString regionLanguage(const QString &regionCode);

private:
    std::vector<std::pair<QString, QString>> regionsMap;
};
