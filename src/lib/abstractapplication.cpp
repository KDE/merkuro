// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "abstractapplication.h"
#include <KAboutData>
#include <KAuthorized>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QDebug>
#include <QGuiApplication>
#include <QMenu>

AbstractApplication::AbstractApplication(QObject *parent)
    : KirigamiAbstractApplication(parent)
{
}

void AbstractApplication::setupActions()
{
    KirigamiAbstractApplication::setupActions();

    auto actionName = QLatin1StringView("options_configure");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardActions::preferences(this, &AbstractApplication::openSettings, this);
        mainCollection()->addAction(action->objectName(), action);
    }

    actionName = QLatin1StringView("open_tag_manager");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openTagManagerAction = mainCollection()->addAction(actionName, this, &AbstractApplication::openTagManager);
        openTagManagerAction->setText(i18n("Manage Tags…"));
        openTagManagerAction->setIcon(QIcon::fromTheme(QStringLiteral("action-rss_tag")));
    }
}

#include "moc_abstractapplication.cpp"
