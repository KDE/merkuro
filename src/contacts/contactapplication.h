// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once
#include "abstractapplication.h"
#include "contactconfig.h"
class QQuickWindow;
class ContactApplication : public AbstractApplication
{
    Q_OBJECT

public:
    explicit ContactApplication(QObject *parent = nullptr);

    QList<KActionCollection *> actionCollections() const override;

    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);

Q_SIGNALS:
    void createNewContact();
    void createNewContactGroup();
    void refreshAll();
    void showMenubarChanged(bool state);

private:
    void setupActions() override;
    void toggleMenubar();
    KActionCollection *mContactCollection = nullptr;
    ContactConfig *const m_config;
};
