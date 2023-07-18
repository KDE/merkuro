// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactplugin.h"
#include "addresseewrapper.h"
#include "contactapplication.h"
#include "contactcollectionmodel.h"
#include "contactconfig.h"
#include "contacteditorbackend.h"
#include "contactgroupeditor.h"
#include "contactgroupwrapper.h"
#include "contactmanager.h"
#include "contactsmodel.h"
#include "emailmodel.h"

#include <QQmlEngine>

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.merkuro.contact"));

    qmlRegisterSingletonType<ContactApplication>("org.kde.merkuro.contact", 1, 0, "ContactApplication", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactApplication;
    });

    qmlRegisterSingletonType<ContactConfig>("org.kde.merkuro.contact", 1, 0, "Config", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactConfig;
    });

    qmlRegisterSingletonType<ContactManager>("org.kde.merkuro.contact", 1, 0, "ContactManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactManager;
    });

    qmlRegisterUncreatableType<EmailModel>("org.kde.merkuro.contact", 1, 0, "EmailModel", QStringLiteral("Enum"));
    qmlRegisterUncreatableType<PhoneModel>("org.kde.merkuro.contact", 1, 0, "PhoneModel", QStringLiteral("Enum"));
    qmlRegisterType<AddresseeWrapper>("org.kde.merkuro.contact", 1, 0, "AddresseeWrapper");
    qmlRegisterType<ContactEditorBackend>("org.kde.merkuro.contact", 1, 0, "ContactEditor");
    qmlRegisterType<ContactGroupWrapper>("org.kde.merkuro.contact", 1, 0, "ContactGroupWrapper");
    qmlRegisterType<ContactGroupEditor>("org.kde.merkuro.contact", 1, 0, "ContactGroupEditor");
    qmlRegisterType<ContactsModel>("org.kde.merkuro.contact", 1, 0, "ContactsModel");
    qRegisterMetaType<KContacts::Picture>("KContacts::Picture");
    qRegisterMetaType<KContacts::PhoneNumber::List>("KContacts::PhoneNumber::List");
    qRegisterMetaType<KContacts::PhoneNumber>("KContacts::PhoneNumber");
    qRegisterMetaType<QAction *>();
}

#include "moc_contactplugin.cpp"
