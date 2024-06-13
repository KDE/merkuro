// SPDX-FileCopyrightText: 2021 Waqar Ahmed <waqar.17a@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QSortFilterProxyModel>

class CommandBarFilterModel final : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
public:
    explicit CommandBarFilterModel(QObject *parent = nullptr);

    [[nodiscard]] QString filterString() const;

    void setFilterString(const QString &string);

Q_SIGNALS:
    void filterStringChanged();

protected:
    [[nodiscard]] bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

    [[nodiscard]] bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_pattern;
};
