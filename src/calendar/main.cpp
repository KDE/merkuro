// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../config-merkuro.h"
#include "importer.h"
#include "mousetracker.h"
#include <KAboutData>
#include <KConfig>
#include <KConfigGroup>
#include <KCrash>
#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowConfig>
#include <KWindowSystem>
#include <QApplication>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDir>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#define HAVE_KICONTHEME __has_include(<KIconTheme>)
#if HAVE_KICONTHEME
#include <KIconTheme>
#endif

#define HAVE_STYLE_MANAGER __has_include(<KStyleManager>)
#if HAVE_STYLE_MANAGER
#include <KStyleManager>
#endif
static void raiseWindow(QWindow *window)
{
    KWindowSystem::updateStartupId(window);
    KWindowSystem::activateWindow(window);
}

int main(int argc, char *argv[])
{
#if HAVE_KICONTHEME
    KIconTheme::initTheme();
#endif
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain(QByteArrayLiteral("merkuro"));
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Merkuro"));
    QCoreApplication::setQuitLockEnabled(false);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

#if HAVE_STYLE_MANAGER
    KStyleManager::initStyle();
#else // !HAVE_STYLE_MANAGER
#if defined(Q_OS_WIN) || defined(Q_OS_MACOS)
    QApplication::setStyle(QStringLiteral("breeze"));
#endif
#endif

    KAboutData aboutData(
        // The program name used internally.
        QStringLiteral("merkuro.calendar"),
        // A displayable program name string.
        i18nc("@title", "Merkuro Calendar"),
        QStringLiteral(MERKURO_VERSION_STRING),
        // Short description of what the app does.
        i18n("Calendar Application"),
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
    aboutData.addAuthor(i18nc("@info:credit", "Felipe Kinoshita"),
                        i18nc("@info:credit", "Developer"),
                        QStringLiteral("kinofhek@gmail.com"),
                        QStringLiteral("https://fhek.gitlab.io"));
    KAboutData::setApplicationData(aboutData);
    KCrash::initialize();
    QGuiApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.merkuro.calendar")));

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    const auto mouseTracker = MouseTracker::instance();
    qmlRegisterSingletonInstance("org.kde.merkuro.calendar.private", 1, 0, "MouseTracker", mouseTracker);

    KDBusService service(KDBusService::Unique);

    qmlRegisterType<Importer>("org.kde.merkuro.calendar.private", 1, 0, "Importer");

    QQmlApplicationEngine engine;

    QObject::connect(&service, &KDBusService::activateRequested, &engine, [&engine, &parser](const QStringList &arguments, const QString &workingDirectory) {
        Q_UNUSED(workingDirectory)
        parser.parse(arguments);
        const auto rootObjects = engine.rootObjects();

        const QStringList args = parser.positionalArguments();

        for (auto obj : rootObjects) {
            auto view = qobject_cast<QQuickWindow *>(obj);
            if (view) {
                raiseWindow(view);

                auto importer = view->findChild<Importer *>(QStringLiteral("ImportHandler"));
                for (const auto &arg : args) {
                    Q_EMIT importer->importCalendarFromFile(QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile));
                }
                return;
            }
        }
    });

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    const auto rootObjects = engine.rootObjects();
    for (auto obj : rootObjects) {
        const auto view = qobject_cast<QQuickWindow *>(obj);
        if (view) {
            KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
            KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
            KWindowConfig::restoreWindowSize(view, windowGroup);
            KWindowConfig::restoreWindowPosition(view, windowGroup);

            view->installEventFilter(mouseTracker);

            const auto args = parser.positionalArguments();

            auto importer = view->findChild<Importer *>(QStringLiteral("ImportHandler"));
            for (const auto &arg : args) {
                Q_EMIT importer->importCalendarFromFile(QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile));
            }

            break;
        }
    }

    return app.exec();
}
