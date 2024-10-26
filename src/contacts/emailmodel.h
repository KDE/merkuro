// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KContacts/Addressee>
#include <QAbstractListModel>
#include <qqmlregistration.h>

class EmailModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QStringList emails READ emails NOTIFY emailsChanged)

public:
    enum ExtraRole {
        TypeRole = Qt::UserRole + 1,
        TypeValueRole,
        DefaultRole,
        EmailRole,
    };
    enum Type {
        Unknown = 0,
        Home = 1,
        Work = 2,
        Other = 4
    };
    Q_ENUM(Type)

    explicit EmailModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void loadContact(const KContacts::Addressee &contact);
    void storeContact(KContacts::Addressee &contact) const;

    Q_INVOKABLE void addEmail(const QString &email, EmailModel::Type type);
    Q_INVOKABLE void deleteEmail(int row);

    QStringList emails() const;

Q_SIGNALS:
    void emailsChanged();
    void changed(const KContacts::Email::List &emails);

private:
    KContacts::Email::List m_emails;
};
