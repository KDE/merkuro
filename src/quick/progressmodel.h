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
    // Properties useful for progress bar displaying overall progress status
    Q_PROPERTY(bool working READ working NOTIFY workingChanged)
    Q_PROPERTY(bool indeterminate READ indeterminate NOTIFY indeterminateChanged)
    Q_PROPERTY(unsigned int progress READ progress NOTIFY progressChanged)

public:
    enum Roles {
        ProgressRole = Qt::UserRole + 1,
        StatusRole,
        CanBeCancelledRole,
    };
    Q_ENUM(Roles)

    explicit ProgressModel(QObject *const parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] bool working() const;
    [[nodiscard]] bool indeterminate() const;
    [[nodiscard]] unsigned int progress() const;

    Q_INVOKABLE void cancelItem(const QString &itemId);

Q_SIGNALS:
    void showProgressView();
    void workingChanged();
    void indeterminateChanged();
    void progressChanged();

public Q_SLOTS:
    void slotProgressItemAdded(KPIM::ProgressItem *const item);
    void slotProgressItemCompleted(KPIM::ProgressItem *const item);
    void slotProgressItemProgress(KPIM::ProgressItem *const item, const unsigned int progress);
    void slotProgressItemStatus(KPIM::ProgressItem *const item, const QString &status);
    void slotProgressItemLabel(KPIM::ProgressItem *const item, const QString &label);

private Q_SLOTS:
    void slotItemProgressDataChanged(KPIM::ProgressItem *const item, const QList<int> roles);
    void updateOverallProperties();

private:
    QList<KPIM::ProgressItem *> m_items;
    bool m_working = false;
    bool m_indeterminate = false;
    unsigned int m_progress = 0;
};
}