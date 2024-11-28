// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <Akonadi/Item>
#include <KMime/Message>
#include <QAbstractItemModel>

class MailModel;

class ThreadedMailModel : public QAbstractItemModel
{
    Q_OBJECT

public:
    enum ExtraRole {
        TitleRole = Qt::UserRole + 1,
        SenderRole,
        FromRole,
        ToRole,
        TextColorRole,
        DateRole,
        DateTimeRole,
        BackgroundColorRole,
        StatusRole,
        FavoriteRole,
        ItemRole,
    };

    explicit ThreadedMailModel(QObject *const object, MailModel *const baseModel);

    QModelIndex index(int row, int column, const QModelIndex &parent) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    int rowCount(const QModelIndex &index = {}) const override;
    int columnCount(const QModelIndex &index = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

public Q_SLOTS:
    void updateThreading();

private:
    struct MailItem {
        Akonadi::Item item;
        KMime::Message::Ptr mail;
        std::weak_ptr<MailItem> parent;
        QList<std::shared_ptr<MailItem>> children;
    };

    MailModel *m_baseModel = nullptr;
    QHash<QString, std::shared_ptr<MailItem>> m_items;
    QList<QString> m_orderedIds;
};
