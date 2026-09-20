// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../addresseewrapper.h"
#include "../contacteditorbackend.h"
#include "../contactrepository.h"

#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemFetchJob>
#include <KJob>
#include <QAbstractItemModel>
#include <QSignalSpy>
#include <QTest>
#include <akonadi/qtest_akonadi.h>
#include <memory>

using namespace Qt::Literals::StringLiterals;

class EditorAndRepositoryTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        AkonadiTest::checkTestIsIsolated();

        m_repository = std::make_unique<ContactRepository>();
        QTRY_VERIFY_WITH_TIMEOUT(m_repository->contactCollections()->rowCount() > 0, 10000);

        auto collectionJob = new Akonadi::CollectionFetchJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive, this);
        QSignalSpy collectionResult(collectionJob, &KJob::result);
        QVERIFY(collectionResult.wait(10000));
        QVERIFY2(!collectionJob->error(), qPrintable(collectionJob->errorString()));

        for (const auto &collection : collectionJob->collections()) {
            if (collection.name() == u"Contacts") {
                m_contactCollection = collection;
                break;
            }
        }
        QVERIFY(m_contactCollection.isValid());
    }

    void editorLoadsAndStoresContact()
    {
        auto itemJob = new Akonadi::ItemFetchJob(m_contactCollection, this);
        itemJob->fetchScope().fetchFullPayload();
        QSignalSpy itemResult(itemJob, &KJob::result);
        QVERIFY(itemResult.wait(10000));
        QVERIFY2(!itemJob->error(), qPrintable(itemJob->errorString()));
        QVERIFY(!itemJob->items().isEmpty());

        ContactEditorBackend editor;
        editor.setMode(ContactEditorBackend::EditMode);
        QSignalSpy contactChanged(&editor, &ContactEditorBackend::contactChanged);
        QSignalSpy errors(&editor, &ContactEditorBackend::errorOccured);
        editor.setItem(itemJob->items().first());

        QVERIFY(contactChanged.wait(10000));
        QVERIFY(errors.isEmpty());
        QVERIFY(editor.contact());
        QCOMPARE(editor.contact()->formattedName(), u"Ada Lovelace"_s);
        QCOMPARE(editor.collectionId(), m_contactCollection.id());

        QSignalSpy savingChanged(&editor, &ContactEditorBackend::savingChanged);
        QSignalSpy finished(&editor, &ContactEditorBackend::finished);
        editor.contact()->setNote(u"Updated by the editor test"_s);
        editor.saveContactInAddressBook();
        QVERIFY(savingChanged.wait(10000));
        QVERIFY(editor.saving());
        QVERIFY(finished.wait(10000));
        QVERIFY(!editor.saving());
        QVERIFY(errors.isEmpty());
    }

private:
    std::unique_ptr<ContactRepository> m_repository;
    Akonadi::Collection m_contactCollection;
};

QTEST_MAIN(EditorAndRepositoryTest)

#include "editorandrepositorytest.moc"
