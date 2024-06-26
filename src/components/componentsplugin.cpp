// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "componentsplugin.h"

#include "helper.h"
#include <KAboutData>
#include <QAction>
#include <QQmlEngine>

void ComponentsPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.merkuro.components"));
    qmlRegisterModule(uri, 1, 0);
    qmlRegisterSingletonType<Helper>(uri, 1, 0, "Helper", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Helper;
    });

    qmlRegisterSingletonType(uri, 1, 0, "About", [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
        return engine->toScriptValue(KAboutData::applicationData());
    });

    qRegisterMetaType<QAction *>();
}

#include "moc_componentsplugin.cpp"
