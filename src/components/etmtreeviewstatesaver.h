// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QObject>
#include <qqmlregistration.h>

#include <KDescendantsProxyModel>

/// Like ETMViewStateSaver but for QML apps
class ETMTreeViewStateSaver : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(KDescendantsProxyModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString configGroup READ configGroup WRITE setConfigGroup NOTIFY configGroupChanged)

public:
    explicit ETMTreeViewStateSaver(QObject *parent = nullptr);

    QString configGroup() const;
    void setConfigGroup(const QString &configGroup);

    KDescendantsProxyModel *model() const;
    void setModel(KDescendantsProxyModel *model);

    QModelIndex indexFromConfigString(const QAbstractItemModel *model, const QString &key) const;
    QString indexToConfigString(const QModelIndex &index) const;

    Q_INVOKABLE void saveState();
    Q_INVOKABLE void restoreState();

Q_SIGNALS:
    void modelChanged();
    void configGroupChanged();

private:
    void processPendingChanges();
    void restoreExpanded();
    bool hasPendingChanges() const;
    void listenToPendingChanges();

    QStringList getExpandedItems(const QModelIndex &index) const;
    KDescendantsProxyModel *m_model;
    QString m_configGroup;
    QSet<QString> m_pendingExpansions;
    QMetaObject::Connection m_rowsInsertedConnection;
};