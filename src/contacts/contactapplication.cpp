// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactapplication.h"
#include "contactconfig.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <KShortcutsDialog>
#include <KWindowConfig>
#include <QIcon>
#include <QQuickWindow>

ContactApplication::ContactApplication(QObject *parent)
    : AbstractApplication(parent)
    , mContactCollection(new KActionCollection(parent, i18n("Contact")))
    , m_config(new ContactConfig(this))
{
    mContactCollection->setComponentDisplayName(i18n("Contact"));
    setupActions();
}

QList<KActionCollection *> ContactApplication::actionCollections() const
{
    return {
        mCollection,
        mContactCollection,
    };
}

void ContactApplication::setupActions()
{
    AbstractApplication::setupActions();

    auto actionName = QLatin1StringView("create_contact");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mContactCollection->addAction(actionName, this, &ContactApplication::createNewContact);
        action->setText(i18n("New Contact…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("contact-new-symbolic")));
    }

    actionName = QLatin1StringView("refresh_all");
    if (KAuthorized::authorizeAction(actionName)) {
        auto refreshAllAction = mContactCollection->addAction(actionName, this, &ContactApplication::refreshAll);
        refreshAllAction->setText(i18n("Refresh All Address Books"));
        refreshAllAction->setIcon(QIcon::fromTheme(QStringLiteral("view-refresh")));

        mContactCollection->addAction(refreshAllAction->objectName(), refreshAllAction);
        mContactCollection->setDefaultShortcut(refreshAllAction, QKeySequence(QKeySequence::Refresh));
    }

    actionName = QLatin1StringView("create_contact_group");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mContactCollection->addAction(actionName, this, &ContactApplication::createNewContactGroup);
        action->setText(i18n("New Contact Group…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("contact-new-symbolic")));
    }
    actionName = QLatin1StringView("toggle_menubar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &ContactApplication::toggleMenubar);
        action->setText(i18n("Show Menubar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("show-menu")));
        action->setCheckable(true);
        action->setChecked(m_config->showMenubar());
        mCollection->setDefaultShortcut(action, QKeySequence(i18n("Ctrl+M")));
    }
    mCollection->readSettings();
    mContactCollection->readSettings();
}

void ContactApplication::saveWindowGeometry(QQuickWindow *window)
{
    KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
}

void ContactApplication::toggleMenubar()
{
    auto state = !m_config->showMenubar();
    m_config->setShowMenubar(state);
    m_config->save();

    Q_EMIT showMenubarChanged(state);
}

#include "moc_contactapplication.cpp"
