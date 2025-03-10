// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
#include "calendarapplication.h"
#include "calendarconfig.h"
#include "calendarmanager.h"
#include "datetimestate.h"
#include "filter.h"
#include "incidencewrapper.h"
#include "models/holidaymodel.h"
#include "models/holidayregionmodel.h"
#include "models/hourlyincidencemodel.h"
#include "models/incidenceoccurrencemodel.h"
#include "models/infinitemerkurocalendarviewmodel.h"
#include "models/itemtagsmodel.h"
#include "models/monthmodel.h"
#include "models/multidayincidencemodel.h"
#include "models/timezonelistmodel.h"
#include "models/todosortfilterproxymodel.h"
#include "remindersmodel.h"
#include "utils.h"
#include <Akonadi/AgentFilterProxyModel>

#include <QAbstractListModel>
#include <QQmlEngine>

#include <Akonadi/FreeBusyManager>
#include <akonadi/calendarsettings.h> //krazy:exclude=camelcase this is a generated file

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.merkuro.calendar"));

    qmlRegisterSingletonType<Utils>(uri, 1, 0, "Utils", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Utils;
    });
    qmlRegisterSingletonType<Akonadi::CalendarSettings>(uri, 1, 0, "CalendarSettings", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return Akonadi::CalendarSettings::self();
    });
    qmlRegisterSingletonType<Akonadi::FreeBusyManager>(uri, 1, 0, "FreeBusyManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return Akonadi::FreeBusyManager::self();
    });
    qmlRegisterType<RemindersModel>(uri, 1, 0, "RemindersModel");
    qmlRegisterModule(uri, 1, 0);
    qRegisterMetaType<KCalendarCore::Incidence::Ptr>();

    qmlRegisterSingletonType<CalendarManager>(uri, 1, 0, "CalendarManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new CalendarManager;
    });

    qmlRegisterSingletonType<DateTimeState>(uri, 1, 0, "DateTimeState", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new DateTimeState;
    });
    qmlRegisterSingletonType<CalendarConfig>(uri, 1, 0, "Config", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new CalendarConfig;
    });
    qmlRegisterSingletonType<CalendarApplication>(uri, 1, 0, "CalendarApplication", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new CalendarApplication;
    });

    qmlRegisterSingletonType<Filter>(uri, 1, 0, "Filter", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Filter;
    });

    qmlRegisterSingletonType<HolidayModel>(uri, 1, 0, "HolidayModel", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new HolidayModel;
    });

    qmlRegisterUncreatableType<IncidenceWrapper>(uri, 1, 0, "IncidenceWrapper", QStringLiteral("Only returned from apis"));
    qmlRegisterType<AttendeesModel>(uri, 1, 0, "AttendeesModel");
    qmlRegisterType<MultiDayIncidenceModel>(uri, 1, 0, "MultiDayIncidenceModel");
    qmlRegisterType<IncidenceOccurrenceModel>(uri, 1, 0, "IncidenceOccurrenceModel");
    qmlRegisterType<TodoSortFilterProxyModel>(uri, 1, 0, "TodoSortFilterProxyModel");
    qmlRegisterType<ItemTagsModel>(uri, 1, 0, "ItemTagsModel");
    qmlRegisterType<HourlyIncidenceModel>(uri, 1, 0, "HourlyIncidenceModel");
    qmlRegisterType<TimeZoneListModel>(uri, 1, 0, "TimeZoneListModel");
    qmlRegisterType<MonthModel>(uri, 1, 0, "MonthModel");
    qmlRegisterType<InfiniteMerkuroCalendarViewModel>(uri, 1, 0, "InfiniteMerkuroCalendarViewModel");
    qmlRegisterType<HolidayRegionModel>(uri, 1, 0, "HolidayRegionModel");

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/CalendarUiUtils.qml")), "org.kde.merkuro.utils", 1, 0, "CalendarUiUtils");
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/IncidenceEditorManager.qml")), "org.kde.merkuro.utils", 1, 0, "IncidenceEditorManager");

    qRegisterMetaType<Akonadi::ETMCalendar::Ptr>();
    qRegisterMetaType<QAbstractProxyModel *>("QAbstractProxyModel*");
    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();
    qRegisterMetaType<Akonadi::CollectionFilterProxyModel *>();
    qRegisterMetaType<QAction *>();

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/qt/qml/org/kde/merkuro/calendar/DatePopupSingleton.qml")),
                             "org.kde.merkuro",
                             1,
                             0,
                             "DatePopupSingleton");
}

#include "moc_calendarplugin.cpp"
