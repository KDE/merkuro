// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailplugin.h"
#include "merkuro_mail_debug.h"

#include <QLoggingCategory>
#include <QQmlEngine>

#include <MailCommon/EntityCollectionOrderProxyModel>
#include <MimeTreeParserCore/FileOpener>
#include <MimeTreeParserCore/MessageParser>

#include "contactimageprovider.h"
#include "helper.h"
#include "mailapplication.h"
#include "mailclient.h"
#include "mailconfig.h"
#include "mailheadermodel.h"
#include "mailmanager.h"
#include "mailmodel.h"
#include "messagehandler.h"
#include "messageloader.h"

#include "identity/identitycryptographyeditorbackendfactory.h"

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.merkuro.mail"));

    qmlRegisterSingletonType<MailApplication>(uri, 1, 0, "IdentityCryptographyEditorBackendFactory", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new IdentityCryptographyEditorBackendFactory;
    });

    qmlRegisterSingletonType<MailApplication>(uri, 1, 0, "MailApplication", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailApplication;
    });

    qmlRegisterSingletonType<MailManager>(uri, 1, 0, "MailManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailManager;
    });

    qmlRegisterSingletonType<MailCollectionHelper>(uri, 1, 0, "MailCollectionHelper", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailCollectionHelper;
    });

    qmlRegisterSingletonType<Akonadi::MailClient>(uri, 1, 0, "MailClient", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::MailClient;
    });

    qmlRegisterSingletonType<MailConfig>(uri, 1, 0, "Config", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailConfig;
    });

    qmlRegisterType<MailHeaderModel>(uri, 1, 0, "MailHeaderModel");
    qmlRegisterType<MessageLoader>(uri, 1, 0, "MessageLoader");
    qmlRegisterType<MessageParser>(uri, 1, 0, "MessageParser");

    qRegisterMetaType<MailModel *>("MailModel*");
    qRegisterMetaType<MailCommon::EntityCollectionOrderProxyModel *>("MailCommon::EntityCollectionOrderProxyModel*");
}

void CalendarPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);
    engine->addImageProvider(QLatin1StringView("contact"), new ContactImageProvider);
}

#include "moc_mailplugin.cpp"
