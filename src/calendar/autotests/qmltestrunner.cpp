// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#define TRANSLATION_DOMAIN "merkuro"

#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <QQmlEngine>
#include <QtQuickTest/quicktest.h>
#include <akonadi/qtest_akonadi.h>

class QmlTestSetup : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    void applicationAvailable()
    {
        AkonadiTest::checkTestIsIsolated();
        KLocalizedString::setApplicationDomain("merkuro");
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        KLocalization::setupLocalizedContext(engine);
    }
};

QUICK_TEST_MAIN_WITH_SETUP(CalendarQmlTests, QmlTestSetup)

#include "qmltestrunner.moc"
