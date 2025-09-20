// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "abstractmerkuroapplication.h"
#include <KAuthorized>
#include <KConfigGroup>
#include <KLocalizedString>

using namespace Qt::StringLiterals;

AbstractMerkuroApplication::AbstractMerkuroApplication(QObject *parent)
    : AbstractKirigamiApplication(parent)
    , m_shared(KSharedConfig::openConfig())
{
}

void AbstractMerkuroApplication::setupActions()
{
    AbstractKirigamiApplication::setupActions();

    auto actionName = QLatin1StringView("options_configure");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardActions::preferences(this, &AbstractMerkuroApplication::openSettings, this);
        mainCollection()->addAction(action->objectName(), action);
    }

    actionName = QLatin1StringView("open_tag_manager");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openTagManagerAction = mainCollection()->addAction(actionName, this, &AbstractMerkuroApplication::openTagManager);
        openTagManagerAction->setText(i18n("Manage Tags…"));
        openTagManagerAction->setIcon(QIcon::fromTheme(u"action-rss_tag"_s));
    }

    actionName = QLatin1StringView("toggle_menubar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mainCollection()->addAction(actionName, this, &AbstractMerkuroApplication::toggleMenubar);
        action->setText(i18n("Show Menubar"));
        action->setIcon(QIcon::fromTheme(u"show-menu"_s));
        action->setCheckable(true);
        KConfigGroup config(m_shared, u"General"_s);
        action->setChecked(config.readEntry(u"showMenubar"_s, true));
        mainCollection()->setDefaultShortcut(action, Qt::CTRL | Qt::Key_M);
    }
}

void AbstractMerkuroApplication::toggleMenubar()
{
    KConfigGroup config(m_shared, u"General"_s);
    auto state = !config.readEntry(u"showMenubar"_s, true);
    config.writeEntry(u"showMenubar"_s, state);
    m_shared->sync();

    Q_EMIT menubarVisibleChanged();
}

bool AbstractMerkuroApplication::menubarVisible() const
{
    KConfigGroup config(m_shared, u"General"_s);
    return config.readEntry(u"showMenubar"_s, true);
}

#include "moc_abstractmerkuroapplication.cpp"
