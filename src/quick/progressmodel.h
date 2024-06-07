// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Libkdepim/ProgressManager>
#include <QAbstractListModel>
#include <QObject>

namespace Akonadi::Quick
{
class ProgressModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        ProgressRole = Qt::UserRole + 1,
        StatusRole,
        CanBeCancelledRole,
    };
    Q_ENUM(Roles)

    explicit ProgressModel(QObject *const parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

Q_SIGNALS:
    void showProgressView();

public Q_SLOTS:
    void slotProgressItemAdded(KPIM::ProgressItem *const item);
    void slotProgressItemCompleted(KPIM::ProgressItem *const item);
    void slotProgressItemProgress(KPIM::ProgressItem *const item, const unsigned int progress);
    void slotProgressItemStatus(KPIM::ProgressItem *const item, const QString &status);
    void slotProgressItemLabel(KPIM::ProgressItem *const item, const QString &label);

private Q_SLOTS:
    void slotItemProgressDataChanged(KPIM::ProgressItem *const item, const QList<int> roles);

private:
    QList<KPIM::ProgressItem *> m_items;
};
}