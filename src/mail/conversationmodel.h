// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/EntityTreeModel>
#include <Akonadi/Item>
#include <QAbstractListModel>
#include <QPointer>
#include <qqmlregistration.h>

class MailPresentationModel;

class ConversationModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Akonadi::Item seedItem READ seedItem WRITE setSeedItem NOTIFY seedItemChanged)
    Q_PROPERTY(MailPresentationModel *folderModel READ folderModel WRITE setFolderModel NOTIFY folderModelChanged)
    Q_PROPERTY(int anchorRow READ anchorRow NOTIFY anchorRowChanged)

public:
    enum Role {
        ItemRole = Akonadi::EntityTreeModel::UserRole + 100,
        ItemIdRole,
        TitleRole,
        FromRole,
        SenderRole,
        ToRole,
        DateTimeRole,
        StatusRole,
    };
    Q_ENUM(Role)

    explicit ConversationModel(QObject *parent = nullptr);

    [[nodiscard]] Akonadi::Item seedItem() const;
    void setSeedItem(const Akonadi::Item &item);

    [[nodiscard]] MailPresentationModel *folderModel() const;
    void setFolderModel(MailPresentationModel *model);

    [[nodiscard]] int anchorRow() const;

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

Q_SIGNALS:
    void seedItemChanged();
    void folderModelChanged();
    void anchorRowChanged();

protected:
    [[nodiscard]] virtual Akonadi::Item::List conversationItems() const;

private:
    void refresh();

    Akonadi::Item m_seedItem;
    QPointer<MailPresentationModel> m_folderModel;
    Akonadi::Item::List m_items;
    int m_anchorRow = -1;
};
