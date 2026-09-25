// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "merkuro_contact_export.h"

#include <Akonadi/Item>
#include <QAbstractListModel>
#include <QSet>
#include <qqmlregistration.h>

namespace Akonadi
{
class ItemSearchJob;
}

class MERKURO_CONTACT_EXPORT ContactActivityModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QStringList emails READ emails WRITE setEmails NOTIFY emailsChanged)
    Q_PROPERTY(Kind kind READ kind WRITE setKind NOTIFY kindChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Kind {
        Messages,
        Events
    };
    Q_ENUM(Kind)

    enum Role {
        TitleRole = Qt::UserRole + 1,
        DateRole,
        PersonRole,
        EmailRole,
        UnreadRole
    };

    explicit ContactActivityModel(QObject *parent = nullptr);

    [[nodiscard]] QStringList emails() const;
    void setEmails(const QStringList &emails);
    [[nodiscard]] Kind kind() const;
    void setKind(Kind kind);

    int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] int count() const;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void openMessage(int row);

Q_SIGNALS:
    void emailsChanged();
    void kindChanged();
    void countChanged();

private:
    friend class ContactActivityModelTest;

    void search();
    void updateItems(Akonadi::Item::List items);

    QStringList m_emails;
    Kind m_kind = Messages;
    Akonadi::ItemSearchJob *m_job = nullptr;
    Akonadi::Item::List m_items;
    QSet<Akonadi::Item::Id> m_markingRead;
};
