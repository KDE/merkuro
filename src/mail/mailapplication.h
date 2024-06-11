// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "abstractapplication.h"

class MailApplication : public AbstractApplication
{
    Q_OBJECT

public:
    explicit MailApplication(QObject *parent = nullptr);
    ~MailApplication() override;

Q_SIGNALS:
    void createNewMail();
    void checkMail();

private:
    void setupActions() override;
};
