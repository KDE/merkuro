// SPDX-FileCopyrightText: 2024 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "abstractmailmodel.h"
#include <Akonadi/Item>

#include <QAbstractListModel>
#include <qqmlregistration.h>

namespace Akonadi
{
class ItemFetchJob;
}
class KJob;

class SearchModel : public QAbstractListModel, public AbstractMailModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString searchString READ searchString WRITE setSearchString NOTIFY searchStringChanged)

public:
    explicit SearchModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] QString searchString() const;
    void setSearchString(const QString &searchString);

Q_SIGNALS:
    void searchStringChanged();

private:
    void slotItemsFetched(KJob *job);

    QString m_searchString;
    Akonadi::ItemFetchJob *m_job;
    Akonadi::Item::List m_items;
};