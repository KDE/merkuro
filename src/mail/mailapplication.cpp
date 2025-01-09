// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "mailapplication.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <QIcon>

using namespace Qt::StringLiterals;

MailApplication::MailApplication(QObject *parent)
    : AbstractMerkuroApplication(parent)
{
    setupActions();
}

MailApplication::~MailApplication() = default;

void MailApplication::setupActions()
{
    AbstractMerkuroApplication::setupActions();

    auto actionName = QLatin1StringView("create_mail");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mainCollection()->addAction(actionName, this, &MailApplication::createNewMail);
        action->setText(i18n("New Mail…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("mail-message-new")));
    }

    const auto checkMailActionName = QLatin1StringView("check_mail");
    if (KAuthorized::authorizeAction(checkMailActionName)) {
        const auto action = mainCollection()->addAction(checkMailActionName, this, &MailApplication::checkMail);
        action->setText(i18n("Check Mail"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("mail-receive")));
    }

    auto action = new QAction(this);
    action->setIcon(QIcon::fromTheme(u"mail-mark-read-symbolic"_s));
    mainCollection()->addAction(u"mark_read"_s, action);

    action = new QAction(this);
    action->setIcon(QIcon::fromTheme(u"mail-mark-unread-symbolic"_s));
    mainCollection()->addAction("mark_unread"_L1, action);

    action = new QAction(this);
    action->setCheckable(true);
    action->setIcon(QIcon::fromTheme(u"mail-mark-important-symbolic"_s));
    mainCollection()->addAction("mark_important"_L1, action);

    action = new QAction(QIcon::fromTheme(u"user-trash-symbolic"_s), i18nc("@action", "Move to Trash"), this);
    mainCollection()->addAction("mail_trash"_L1, action);

    action = new QAction(QIcon::fromTheme(u"document-save-as-symbolic"_s), i18nc("@action", "Save as..."), this);
    mainCollection()->addAction("mail_save_as"_L1, action);

    action = new QAction(QIcon::fromTheme(u"edit-move-symbolic"_s), i18nc("@action", "Move to..."), this);
    mainCollection()->addAction("mail_move_to"_L1, action);

    action = new QAction(QIcon::fromTheme(u"edit-copy-symbolic"_s), i18nc("@action", "Copy to..."), this);
    mainCollection()->addAction("mail_copy_to"_L1, action);

    readSettings();
}

#include "moc_mailapplication.cpp"
