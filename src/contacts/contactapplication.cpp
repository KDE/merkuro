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

using namespace Qt::StringLiterals;

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
        action->setIcon(QIcon::fromTheme(u"contact-new-symbolic"_s));
    }

    actionName = QLatin1StringView("refresh_all");
    if (KAuthorized::authorizeAction(actionName)) {
        auto refreshAllAction = mContactCollection->addAction(actionName, this, &ContactApplication::refreshAll);
        refreshAllAction->setText(i18n("Refresh All Address Books"));
        refreshAllAction->setIcon(QIcon::fromTheme(u"view-refresh"_s));

        mContactCollection->addAction(refreshAllAction->objectName(), refreshAllAction);
        mContactCollection->setDefaultShortcut(refreshAllAction, QKeySequence(QKeySequence::Refresh));
    }

    actionName = QLatin1StringView("create_contact_group");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mContactCollection->addAction(actionName, this, &ContactApplication::createNewContactGroup);
        action->setText(i18n("New Contact Group…"));
        action->setIcon(QIcon::fromTheme(u"contact-new-symbolic"_s));
    }

    auto action = new QAction(QIcon::fromTheme(u"edit-entry-symbolic"_s), i18nc("@action", "Edit contact…"), this);
    mainCollection()->addAction("contact_edit"_L1, action);

    action = new QAction(QIcon::fromTheme(u"delete-symbolic"_s), i18nc("@action", "Delete contact"), this);
    mainCollection()->addAction("contact_delete"_L1, action);

    action = new QAction(QIcon::fromTheme(u"edit-move-symbolic"_s), i18nc("@action", "Move to…"), this);
    mainCollection()->addAction("contact_move_to"_L1, action);

    action = new QAction(QIcon::fromTheme(u"edit-copy-symbolic"_s), i18nc("@action", "Copy to…"), this);
    mainCollection()->addAction("contact_copy_to"_L1, action);

    readSettings();
}

void ContactApplication::saveWindowGeometry(QQuickWindow *window)
{
    KConfig dataResource(u"data"_s, KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, u"Window"_s);
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
}

#include "moc_contactapplication.cpp"
