// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "merkuro_mail_debug.h"
#include "mailplugin.h"

#include <QQmlEngine>
#include <QLoggingCategory>

#include <MailCommon/EntityCollectionOrderProxyModel>
#include <MimeTreeParserCore/FileOpener>
#include <MimeTreeParserCore/MessageParser>

#include "contactimageprovider.h"
#include "helper.h"
#include "mailapplication.h"
#include "mailheadermodel.h"
#include "mailmanager.h"
#include "mailmodel.h"
#include "messagehandler.h"
#include "messageloader.h"
#include "mailheadermodel.h"
#include "mailclient.h"

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

    qmlRegisterSingletonType<MailManager>("org.kde.merkuro.mail", 1, 0, "MailManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailManager;
    });

    qmlRegisterSingletonType<MailCollectionHelper>("org.kde.merkuro.mail", 1, 0, "MailCollectionHelper", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailCollectionHelper;
    });

    qmlRegisterSingletonType<Akonadi::MailClient>("org.kde.merkuro.mail", 1, 0, "MailClient", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::MailClient;
    });

    qmlRegisterType<MailHeaderModel>("org.kde.merkuro.mail", 1, 0, "MailHeaderModel");
    qmlRegisterType<MessageLoader>(uri, 1, 0, "MessageLoader");
    qmlRegisterType<MessageParser>(uri, 1, 0, "MessageParser");

    qRegisterMetaType<MailModel *>("MailModel*");
    qRegisterMetaType<MailCommon::EntityCollectionOrderProxyModel *>("MailCommon::EntityCollectionOrderProxyModel*");
}

void CalendarPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);
    engine->addImageProvider(QLatin1String("contact"), new ContactImageProvider);
}

#include "moc_mailplugin.cpp"
