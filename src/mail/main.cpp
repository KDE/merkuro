// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../config-merkuro.h"
#include "messagehandler.h"
#include <KAboutData>
#include <KCrash>
#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowSystem>
#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#if KI18N_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <KLocalizedQmlContext>
#endif

#include <KIconTheme>

#include <KStyleManager>
static void raiseWindow(QWindow *window)
{
    KWindowSystem::updateStartupId(window);
    KWindowSystem::activateWindow(window);
}

int main(int argc, char *argv[])
{
    KIconTheme::initTheme();
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain(QByteArrayLiteral("merkuro"));
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Merkuro Mail"));
    QCoreApplication::setQuitLockEnabled(false);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    KStyleManager::initStyle();

    KAboutData aboutData(
        // The program name used internally.
        QStringLiteral("merkuro.mail"),
        // A displayable program name string.
        i18nc("@title", "Merkuro Mail"),
        QStringLiteral(MERKURO_VERSION_STRING),
        // Short description of what the app does.
        i18n("Email Client"),
        // The license this code is released under.
        KAboutLicense::GPL_V3,
        // Copyright Statement.
        i18n("(c) KDE Community 2021-2024"));
    aboutData.setBugAddress("https://bugs.kde.org/enter_bug.cgi?format=guided&product=merkuro&version=" + QStringLiteral(MERKURO_VERSION_STRING).toUtf8());
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"),
                        i18nc("@info:credit", "Maintainer"),
                        QStringLiteral("carl@carlschwan.eu"),
                        QStringLiteral("https://carlschwan.eu"),
                        QUrl(QStringLiteral("https://carlschwan.eu/avatar.png")));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"),
                        i18nc("@info:credit", "Maintainer"),
                        QStringLiteral("claudio.cambra@gmail.com"),
                        QStringLiteral("https://claudiocambra.com"));
    KAboutData::setApplicationData(aboutData);
    KCrash::initialize();
    QGuiApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.merkuro.mail")));

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    KDBusService service(KDBusService::Unique);

    const auto options = parser.optionNames();
    const auto args = parser.positionalArguments();
    QQmlApplicationEngine engine;
#if KI18N_VERSION < QT_VERSION_CHECK(6, 8, 0)
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
#else
    engine.rootContext()->setContextObject(new KLocalizedQmlContext(&engine));
#endif
    if (!args.isEmpty()) {
        qmlRegisterType<MessageHandler>("org.kde.merkuro.mail.desktop", 1, 0, "MessageHandler");
        engine.loadFromModule("org.kde.merkuro.mail", "OpenMbox");
        const auto rootObjects = engine.rootObjects();
        if (rootObjects.isEmpty()) {
            return -1;
        }
        parser.process(app);

        const QStringList args = parser.positionalArguments();
        for (auto obj : rootObjects) {
            auto view = qobject_cast<QQuickWindow *>(obj);
            auto messageHandler = view->findChild<MessageHandler *>(QStringLiteral("MessageHandler"));
            const auto file = QUrl::fromUserInput(args.at(args.count() - 1), QDir::currentPath());
            messageHandler->open(file);
        }
    } else {
        engine.loadFromModule("org.kde.merkuro.mail", "Main");

        QObject::connect(&service,
                         &KDBusService::activateRequested,
                         &engine,
                         [&engine](const QStringList & /*arguments*/, const QString & /*workingDirectory*/) {
                             const auto rootObjects = engine.rootObjects();
                             for (auto obj : rootObjects) {
                                 auto view = qobject_cast<QQuickWindow *>(obj);
                                 if (view) {
                                     raiseWindow(view);
                                     return;
                                 }
                             }
                         });
    }

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
