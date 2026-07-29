// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2024 Carl Schwan <carl@carlschwan.eu>

#include <QApplication>

#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "../config-merkuro.h"
#include <KAboutData>
#include <KCrash>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KirigamiAddons/App/KirigamiAppDefaults>

#ifdef Q_OS_WINDOWS
#include <Windows.h>
#endif

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    KirigamiAppDefaults::apply(&app);

    KLocalizedString::setApplicationDomain("merkurolauncher");
    QCoreApplication::setOrganizationName(u"KDE"_s);

    KAboutData aboutData(u"merkurolauncher"_s,
                         i18nc("@title", "Merkuro Launcher"),
                         QStringLiteral(MERKURO_VERSION_STRING),
                         i18n("merkuro Launcher"),
                         KAboutLicense::GPL,
                         i18n("© 2024"));
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"), i18nc("@info:credit", "Maintainer"), u"carl@carlschwan.eu"_s, u"https://carlschwan.eu.com"_s);
    aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"org.kde.merkuro.words"_s));

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextObject(new KLocalizedQmlContext(&engine));
    engine.loadFromModule("org.kde.merkuro", u"Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
