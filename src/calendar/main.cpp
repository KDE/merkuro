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
#include <KIconTheme>
#include <KLocalizedQmlContext>
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
#include <QTimer>
#define HAVE_KICONTHEME __has_include(<KIconTheme>)
#if HAVE_KICONTHEME
#include <KIconTheme>
#endif

#include <KStyleManager>
using namespace Qt::Literals::StringLiterals;
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
    KLocalizedString::setApplicationDomain("merkuro"_ba);
    QCoreApplication::setOrganizationName(u"KDE"_s);
    QCoreApplication::setApplicationName(u"Merkuro"_s);
    QCoreApplication::setQuitLockEnabled(false);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }

    KStyleManager::initStyle();

    KAboutData aboutData(
        // The program name used internally.
        u"merkuro.calendar"_s,
        // A displayable program name string.
        i18nc("@title", "Merkuro Calendar"),
        QStringLiteral(MERKURO_VERSION_STRING),
        // Short description of what the app does.
        i18n("Calendar Application"),
        // The license this code is released under.
        KAboutLicense::GPL_V3,
        // Copyright Statement.
        i18n("© KDE Community 2021–2024"));
    aboutData.setBugAddress("https://bugs.kde.org/enter_bug.cgi?format=guided&product=merkuro&version=" + QStringLiteral(MERKURO_VERSION_STRING).toUtf8());
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"),
                        i18nc("@info:credit", "Maintainer"),
                        u"carl@carlschwan.eu"_s,
                        u"https://carlschwan.eu"_s,
                        QUrl(u"https://carlschwan.eu/avatar.png"_s));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"),
                        i18nc("@info:credit", "Maintainer"),
                        u"claudio.cambra@gmail.com"_s,
                        u"https://claudiocambra.com"_s);
    aboutData.addAuthor(i18nc("@info:credit", "Felipe Kinoshita"), i18nc("@info:credit", "Developer"), u"kinofhek@gmail.com"_s, u"https://fhek.gitlab.io"_s);
    KAboutData::setApplicationData(aboutData);
    KCrash::initialize();
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"org.kde.merkuro.calendar"_s));

    QCommandLineParser parser;
    QCommandLineOption selfTestOpt(QStringLiteral("self-test"), QStringLiteral("internal, for automated testing"));
    parser.addOption(selfTestOpt);
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    const auto mouseTracker = MouseTracker::instance();

    KDBusService service(KDBusService::Unique);

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

                auto importer = view->findChild<Importer *>(u"ImportHandler"_s);
                for (const auto &arg : args) {
                    Q_EMIT importer->importCalendarFromFile(QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile));
                }
                return;
            }
        }
    });

    engine.rootContext()->setContextObject(new KLocalizedQmlContext(&engine));
    engine.loadFromModule("org.kde.merkuro.calendar", "Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    const auto rootObjects = engine.rootObjects();
    for (auto obj : rootObjects) {
        const auto view = qobject_cast<QQuickWindow *>(obj);
        if (view) {
            KConfig dataResource(u"data"_s, KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
            KConfigGroup windowGroup(&dataResource, u"Window"_s);
            KWindowConfig::restoreWindowSize(view, windowGroup);
            KWindowConfig::restoreWindowPosition(view, windowGroup);

            view->installEventFilter(mouseTracker);

            const auto args = parser.positionalArguments();

            auto importer = view->findChild<Importer *>(u"ImportHandler"_s);
            for (const auto &arg : args) {
                Q_EMIT importer->importCalendarFromFile(QUrl::fromUserInput(arg, QDir::currentPath(), QUrl::AssumeLocalFile));
            }

            break;
        }
    }

    if (parser.isSet(selfTestOpt)) {
        QTimer::singleShot(std::chrono::milliseconds(250), &app, &QCoreApplication::quit);
    }

    return app.exec();
}
