// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "akonadiquickplugin.h"

#include "agentconfiguration.h"
#include "collection.h"
#include "collectioncomboboxmodel.h"
#include "collectionpickermodel.h"
#include "identityeditorbackend.h"
#include "identitymodel.h"
#include "identityutils.h"
#include "identitywrapper.h"
#include "mimetypes.h"
#include "tagmanager.h"

#include <Akonadi/Collection>
#include <QQmlEngine>

void AkonadiQuickPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.akonadi"));

    qmlRegisterSingletonType<Akonadi::Quick::MimeTypes>("org.kde.akonadi", 1, 0, "MimeTypes", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::Quick::MimeTypes;
    });

    qmlRegisterSingletonType<TagManager>("org.kde.akonadi", 1, 0, "TagManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new TagManager;
    });

    qmlRegisterSingletonType<Akonadi::Quick::IdentityUtils>("org.kde.akonadi", 1, 0, "IdentityUtils", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::Quick::IdentityUtils;
    });

    qmlRegisterType<AgentConfiguration>("org.kde.akonadi", 1, 0, "AgentConfiguration");
    qmlRegisterType<Akonadi::Quick::CollectionComboBoxModel>("org.kde.akonadi", 1, 0, "CollectionComboBoxModel");
    qmlRegisterType<Akonadi::Quick::CollectionPickerModel>("org.kde.akonadi", 1, 0, "CollectionPickerModel");
    qmlRegisterType<Akonadi::Quick::IdentityModel>("org.kde.akonadi", 1, 0, "IdentityModel");
    qmlRegisterType<Akonadi::Quick::IdentityEditorBackend>("org.kde.akonadi", 1, 0, "IdentityEditorBackend");

    qmlRegisterUncreatableType<Akonadi::Quick::Collection>("org.kde.akonadi", 1, 0, "Collection", QStringLiteral("It's just an enum"));
    qmlRegisterUncreatableType<Akonadi::Quick::IdentityWrapper>("org.kde.akonadi",
                                                                1,
                                                                0,
                                                                "IdentityWrapper",
                                                                QStringLiteral("A QML-friendly wrapper of Identity"));
}

#include "moc_akonadiquickplugin.cpp"
