// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <QAbstractItemModel>

class MailModel;

class ThreadedMailModel : public QAbstractItemModel
{
    Q_OBJECT

public:
    explicit ThreadedMailModel(QObject *const object, MailModel *const baseModel);

    QModelIndex index(int row, int column, const QModelIndex &parent) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    int rowCount(const QModelIndex &index = {}) const override;
    int columnCount(const QModelIndex &index = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    MailModel *m_baseModel = nullptr;
};
