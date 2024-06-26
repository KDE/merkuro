// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once
#include "actionsmodel.h"
#include <KActionCollection>
#include <QObject>
#include <QSortFilterProxyModel>

class AbstractApplication : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)

public:
    explicit AbstractApplication(QObject *parent = nullptr);
    ~AbstractApplication();

    Q_INVOKABLE void configureShortcuts();
    Q_INVOKABLE QAction *action(const QString &actionName);

    virtual QList<KActionCollection *> actionCollections() const = 0;
    QSortFilterProxyModel *actionsModel();

Q_SIGNALS:
    void openLanguageSwitcher();
    void openSettings();
    void openAboutPage();
    void openAboutKDEPage();
    void openKCommandBarAction();
    void openTagManager();

protected:
    virtual void setupActions();
    KActionCollection *const mCollection;

private:
    void quit();

    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
};
