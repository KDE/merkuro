// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "mailapplication.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <QIcon>

MailApplication::MailApplication(QObject *parent)
    : AbstractApplication(parent)
    , m_config(new MailConfig(this))
{
    setupActions();
}

MailApplication::~MailApplication() = default;

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

    actionName = QLatin1StringView("toggle_menubar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &MailApplication::toggleMenubar);
        action->setText(i18n("Show Menubar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("show-menu")));
        action->setCheckable(true);
        action->setChecked(m_config->showMenubar());
        mCollection->setDefaultShortcut(action, QKeySequence(i18n("Ctrl+M")));
    }

    mCollection->readSettings();
}

void MailApplication::toggleMenubar()
{
    auto state = !m_config->showMenubar();
    m_config->setShowMenubar(state);
    m_config->save();

    Q_EMIT showMenubarChanged(state);
}

QList<KActionCollection *> MailApplication::actionCollections() const
{
    return {
        mCollection,
    };
}

#include "moc_mailapplication.cpp"
