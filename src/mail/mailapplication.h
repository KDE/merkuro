// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once
#include "abstractapplication.h"
#include "mailconfig.h"

class MailApplication : public AbstractApplication
{
    Q_OBJECT

public:
    explicit MailApplication(QObject *parent = nullptr);
    ~MailApplication() override;

    QList<KActionCollection *> actionCollections() const override;

Q_SIGNALS:
    void createNewMail();
    void checkMail();
    void showMenubarChanged(bool state);

private:
    void setupActions() override;
    void toggleMenubar();
    MailConfig *const m_config;
};
