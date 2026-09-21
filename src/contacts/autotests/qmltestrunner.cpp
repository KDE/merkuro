// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#define TRANSLATION_DOMAIN "merkuro"

#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KContacts/Addressee>
#include <KJob>
#include <KLocalizedQmlContext>
#include <QQmlContext>
#include <QQmlEngine>
#include <QTimer>
#include <QtQuickTest/quicktest.h>

class ContactTestItemProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::Item item READ item NOTIFY itemChanged)

public:
    Akonadi::Item item() const
    {
        return m_item;
    }

    Q_INVOKABLE void createContact()
    {
        auto job = new Akonadi::CollectionFetchJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive);
        connect(job, &KJob::result, this, [this](KJob *job) {
            const auto fetchJob = qobject_cast<Akonadi::CollectionFetchJob *>(job);
            if (!fetchJob) {
                Q_EMIT errorOccurred(QStringLiteral("Failed to fetch contact collections"));
                return;
            }

            for (const auto &collection : fetchJob->collections()) {
                if (collection.name() != QStringLiteral("Contacts")) {
                    continue;
                }

                KContacts::Addressee addressee;
                addressee.setFormattedName(QStringLiteral("QML Editor Test Contact"));
                Akonadi::Item item;
                item.setMimeType(KContacts::Addressee::mimeType());
                item.setPayload(addressee);
                auto itemJob = new Akonadi::ItemCreateJob(item, collection);
                connect(itemJob, &KJob::result, this, [this](KJob *job) {
                    const auto createJob = qobject_cast<Akonadi::ItemCreateJob *>(job);
                    if (!createJob || createJob->error()) {
                        Q_EMIT errorOccurred(QStringLiteral("Failed to create the test contact"));
                        return;
                    }
                    m_item = createJob->item();
                    Q_EMIT itemChanged();
                });
                return;
            }
            QTimer::singleShot(100, this, &ContactTestItemProvider::createContact);
        });
    }

Q_SIGNALS:
    void itemChanged();
    void errorOccurred(const QString &message);

private:
    Akonadi::Item m_item;
};

class QmlTestSetup : public QObject
{
    Q_OBJECT

    ContactTestItemProvider m_itemProvider;

public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        KLocalization::setupLocalizedContext(engine);
        engine->rootContext()->setContextProperty(QStringLiteral("contactTestItemProvider"), &m_itemProvider);
        m_itemProvider.createContact();
    }
};

QUICK_TEST_MAIN_WITH_SETUP(ContactQmlTests, QmlTestSetup)

#include "qmltestrunner.moc"
