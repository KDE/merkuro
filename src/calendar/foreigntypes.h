// SPDX-FileCopyrightText: 2025 Tobias Fella <tobias.fella@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <QQmlEngine>

#include <Akonadi/FreeBusyManager>
#include <akonadi/calendarsettings.h> //krazy:exclude=camelcase this is a generated file

#include "calendarconfig.h"

struct CalendarSettingsForeign {
    Q_GADGET
    QML_SINGLETON
    QML_FOREIGN(Akonadi::CalendarSettings)
    QML_NAMED_ELEMENT(CalendarSettings)
public:
    static Akonadi::CalendarSettings *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(Akonadi::CalendarSettings::self(), QQmlEngine::CppOwnership);
        return Akonadi::CalendarSettings::self();
    }
};

struct FreeBusyManagerForeign {
    Q_GADGET
    QML_SINGLETON
    QML_FOREIGN(Akonadi::FreeBusyManager)
    QML_NAMED_ELEMENT(FreeBusyManager)
public:
    static Akonadi::FreeBusyManager *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(Akonadi::FreeBusyManager::self(), QQmlEngine::CppOwnership);
        return Akonadi::FreeBusyManager::self();
    }
};

struct ConfigForeign {
    Q_GADGET
    QML_SINGLETON
    QML_FOREIGN(CalendarConfig)
    QML_NAMED_ELEMENT(Config)
public:
    static CalendarConfig *create(QQmlEngine *, QJSEngine *)
    {
        return new CalendarConfig;
    }
};

struct ETMCalendarForeign {
    Q_GADGET
    QML_UNCREATABLE("")
    QML_FOREIGN(Akonadi::ETMCalendar::Ptr)
    QML_NAMED_ELEMENT(ETMCalendarPtr)
};
