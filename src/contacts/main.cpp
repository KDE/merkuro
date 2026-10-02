// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../config-merkuro.h"
#include <KAboutData>
#include <KCrash>
#include <KDBusService>
#include <KIconTheme>
#include <KLocalizedString>
#include <KWindowSystem>
#include <KirigamiAddons/App/KirigamiAppDefaults>
#include <QApplication>
#include <QCommandLineParser>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>

#include <KLocalizedQmlContext>
#include <Libkleo/KeyCache>

using namespace Qt::Literals::StringLiterals;
static void raiseWindow(QWindow *window)
{
    KWindowSystem::updateStartupId(window);
    KWindowSystem::activateWindow(window);
}

int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("merkuro"_ba);
    QCoreApplication::setOrganizationName(u"KDE"_s);
    QCoreApplication::setApplicationName(u"Merkuro Contact"_s);
    QCoreApplication::setQuitLockEnabled(false);

    KirigamiAppDefaults::apply(&app);

    auto aboutData = KAboutData::fromAppStreamId(u"org.kde.merkuro.contact"_s);
    aboutData.setComponentName(u"merkuro.contacts"_s);
    aboutData.setVersion(MERKURO_VERSION_STRING);
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"),
                        i18nc("@info:credit", "Maintainer"),
                        u"carl@carlschwan.eu"_s,
                        u"https://carlschwan.eu"_s,
                        QUrl(u"https://carlschwan.eu/avatar.png"_s));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"),
                        i18nc("@info:credit", "Maintainer"),
                        u"claudio.cambra@gmail.com"_s,
                        u"https://claudiocambra.com"_s);
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"org.kde.merkuro.contact"_s));

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    KDBusService service(KDBusService::Unique);

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    engine.loadFromModule("org.kde.merkuro.contact", "Main");

    QObject::connect(&service, &KDBusService::activateRequested, &engine, [&engine](const QStringList & /*arguments*/, const QString & /*workingDirectory*/) {
        const auto rootObjects = engine.rootObjects();
        for (auto obj : rootObjects) {
            auto view = qobject_cast<QQuickWindow *>(obj);
            if (view) {
                raiseWindow(view);
                return;
            }
        }
    });

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    auto keyCache = Kleo::KeyCache::mutableInstance();
    keyCache->startKeyListing();

    return app.exec();
}
