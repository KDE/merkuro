// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "incidencewrapper.h"
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest/quicktest.h>
#include <akonadi/qtest_akonadi.h>

class QmlTestSetup : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    void prepareEditor(IncidenceWrapper *wrapper)
    {
        Akonadi::Item item(999999);
        item.setRevision(0);
        item.setPayload<KCalendarCore::Incidence::Ptr>(KCalendarCore::Incidence::Ptr(wrapper->incidencePtr()->clone()));
        wrapper->setIncidenceItem(item);
        wrapper->triggerEditMode();
    }

    void updateEditor(IncidenceWrapper *wrapper, const QString &summary)
    {
        auto item = wrapper->incidenceItem();
        item.setRevision(item.revision() + 1);
        const KCalendarCore::Incidence::Ptr incidence(item.payload<KCalendarCore::Incidence::Ptr>()->clone());
        incidence->setSummary(summary);
        item.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
        wrapper->recordExternalChange(item);
    }

    void removeEditor(IncidenceWrapper *wrapper)
    {
        wrapper->recordRemoval();
    }

    void applicationAvailable()
    {
        AkonadiTest::checkTestIsIsolated();
        KLocalizedString::setApplicationDomain("merkuro");
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        KLocalization::setupLocalizedContext(engine);
        engine->rootContext()->setContextProperty(QStringLiteral("editorTestHelper"), this);
    }
};

QUICK_TEST_MAIN_WITH_SETUP(CalendarQmlTests, QmlTestSetup)

#include "qmltestrunner.moc"
