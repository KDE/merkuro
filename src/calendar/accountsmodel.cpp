/*
 *  SPDX-FileCopyrightText: 2025 Nicolas Fella <nicolas.fella@gmx.de>
 *
 *  SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "accountsmodel.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#include <QGuiApplication>
#include <QVariantMap>

using namespace Qt::Literals;

AccountsModel::AccountsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // register
    QDBusMessage rm =
        QDBusMessage::createMethodCall(u"org.kde.KOnlineAccounts"_s, u"/org/kde/KOnlineAccounts"_s, u"org.kde.KOnlineAccounts.Manager"_s, u"registerApp"_s);

    rm.setArguments({u"org.kde.akonadi"_s});
    QDBusConnection::sessionBus().call(rm);

    // watch for granted accounts
    bool ret = QDBusConnection::sessionBus().connect(u"org.kde.KOnlineAccounts"_s,
                                                     u"/org/kde/KOnlineAccounts"_s,
                                                     u"org.kde.KOnlineAccounts.Manager"_s,
                                                     u"accountAccessGranted"_s,
                                                     this,
                                                     SLOT(slotAccountCreationFinished(const QDBusObjectPath &, const QString &)));
    Q_ASSERT(ret);

    load();
}

void AccountsModel::load()
{
    m_accounts.clear();

    QDBusMessage msg =
        QDBusMessage::createMethodCall(u"org.kde.KOnlineAccounts"_s, u"/org/kde/KOnlineAccounts"_s, u"org.freedesktop.DBus.Properties"_s, u"Get"_s);
    msg.setArguments({u"org.kde.KOnlineAccounts.Manager"_s, u"accounts"_s});
    QDBusReply<QDBusVariant> reply = QDBusConnection::sessionBus().call(msg);

    if (!reply.isValid()) {
        qWarning() << "error" << reply.error();
    }
    const auto accounts = qdbus_cast<QList<QDBusObjectPath>>(reply.value().variant());

    beginResetModel();

    for (const QDBusObjectPath &accountPath : accounts) {
        addFromDBus(accountPath);
    }

    endResetModel();
}

void AccountsModel::addFromDBus(const QDBusObjectPath &accountPath)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(u"org.kde.KOnlineAccounts"_s, accountPath.path(), u"org.freedesktop.DBus.Properties"_s, u"GetAll"_s);
    msg.setArguments({u"org.kde.KOnlineAccounts.Account"_s});
    QDBusReply<QVariantMap> reply = QDBusConnection::sessionBus().call(msg);
    if (!reply.isValid()) {
        qWarning() << "error" << reply.error();
    }

    QVariantMap result = reply.value();

    const QString name = result[u"displayName"_s].toString();
    const QStringList types = result[u"types"_s].toStringList();
    const QString icon = result[u"icon"_s].toString();

    m_accounts.append({
        .path = accountPath,
        .name = name,
        .icon = icon,
    });
}

QHash<int, QByteArray> AccountsModel::roleNames() const
{
    return {
        {Name, "name"},
        {Path, "path"},
        {IconName, "iconName"},
    };
}

int AccountsModel::rowCount(const QModelIndex & /*parent*/) const
{
    return m_accounts.size();
}

QVariant AccountsModel::data(const QModelIndex &index, int role) const
{
    switch (static_cast<Roles>(role)) {
    case Name:
        return m_accounts[index.row()].name;
    case Path:
        return m_accounts[index.row()].path.path();
    case IconName:
        return m_accounts[index.row()].icon;
    }

    return QVariant();
}

void AccountsModel::requestNew()
{
    QDBusMessage m =
        QDBusMessage::createMethodCall(u"org.kde.KOnlineAccounts"_s, u"/org/kde/KOnlineAccounts"_s, u"org.kde.KOnlineAccounts.Manager"_s, u"requestAccount"_s);

    m.setArguments({QStringList{u"caldav"_s, u"google"_s}});

    QDBusConnection::sessionBus().asyncCall(m);
}

void AccountsModel::slotAccountCreationFinished(const QDBusObjectPath &path, const QString & /*xdgActivationToken*/)
{
    beginInsertRows({}, m_accounts.size(), m_accounts.size());
    addFromDBus(path);
    endInsertRows();
}
