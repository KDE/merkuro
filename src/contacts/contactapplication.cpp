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
    : AbstractMerkuroApplication(parent)
    , mContactCollection(new KirigamiActionCollection(parent, i18n("Contact")))
{
    mContactCollection->setComponentDisplayName(i18n("Contact"));
    setupActions();
}

QList<KirigamiActionCollection *> ContactApplication::actionCollections() const
{
    return {
        mainCollection(),
        mContactCollection,
    };
}

void ContactApplication::setupActions()
{
    AbstractMerkuroApplication::setupActions();

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

    readSettings();
}

void ContactApplication::saveWindowGeometry(QQuickWindow *window)
{
    KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
}

#include "moc_contactapplication.cpp"
