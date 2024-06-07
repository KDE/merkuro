// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "mailapplication.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <QIcon>

MailApplication::MailApplication(QObject *parent)
    : AbstractApplication(parent)
{
    setupActions();
}

void MailApplication::setupActions()
{
    AbstractApplication::setupActions();

    auto actionName = QLatin1StringView("create_mail");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &MailApplication::createNewMail);
        action->setText(i18n("New Mail…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("mail-message-new")));
    }

    const auto checkMailActionName = QLatin1StringView("check_mail");
    if (KAuthorized::authorizeAction(checkMailActionName)) {
        const auto action = mCollection->addAction(checkMailActionName, this, &MailApplication::checkMail);
        action->setText(i18n("Check Mail"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("mail-receive")));
    }

    mCollection->readSettings();
}

QList<KActionCollection *> MailApplication::actionCollections() const
{
    return {
        mCollection,
    };
}

#include "moc_mailapplication.cpp"
