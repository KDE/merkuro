// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "../addresseewrapper.h"
#include "../contacteditorbackend.h"
#include "../contactgroupeditor.h"
#include "../contactrepository.h"

#include <Akonadi/CollectionFetchJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemMoveJob>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KJob>
#include <QAbstractItemModel>
#include <QItemSelectionModel>
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
        QVERIFY(m_repository->filteredContacts());
        QTRY_VERIFY_WITH_TIMEOUT(m_repository->contactCollections()->rowCount() > 0, 5000);

        auto collectionJob = new Akonadi::CollectionFetchJob(Akonadi::Collection::root(), Akonadi::CollectionFetchJob::Recursive, this);
        QSignalSpy collectionResult(collectionJob, &KJob::result);
        QVERIFY(collectionResult.wait(5000));
        QVERIFY2(!collectionJob->error(), qPrintable(collectionJob->errorString()));

        for (const auto &collection : collectionJob->collections()) {
            if (collection.name() == u"Contacts") {
                m_contactCollection = collection;
            } else if (collection.name() == u"Other Contacts") {
                m_otherContactCollection = collection;
            }
        }
        QVERIFY(m_contactCollection.isValid());
        QVERIFY(m_otherContactCollection.isValid());
    }

    void editorLoadsAndStoresContact()
    {
        auto itemJob = new Akonadi::ItemFetchJob(m_contactCollection, this);
        itemJob->fetchScope().fetchFullPayload();
        QSignalSpy itemResult(itemJob, &KJob::result);
        QVERIFY(itemResult.wait(3000));
        QVERIFY2(!itemJob->error(), qPrintable(itemJob->errorString()));
        QVERIFY(!itemJob->items().isEmpty());

        for (const auto &item : itemJob->items()) {
            if (item.mimeType() == KContacts::Addressee::mimeType()) {
                m_contactItem = item;
            } else if (item.mimeType() == KContacts::ContactGroup::mimeType()) {
                m_contactGroupItem = item;
            }
        }
        QVERIFY(m_contactItem.isValid());
        QVERIFY(m_contactGroupItem.isValid());

        ContactEditorBackend editor;
        editor.setMode(ContactEditorBackend::EditMode);
        QSignalSpy contactChanged(&editor, &ContactEditorBackend::contactChanged);
        QSignalSpy errors(&editor, &ContactEditorBackend::errorOccured);
        editor.setItem(m_contactItem);

        QVERIFY(contactChanged.wait(3000));
        QVERIFY(errors.isEmpty());
        QVERIFY(editor.contact());
        QCOMPARE(editor.contact()->formattedName(), u"Ada Lovelace"_s);
        QCOMPARE(editor.collectionId(), m_contactCollection.id());

        QSignalSpy savingChanged(&editor, &ContactEditorBackend::savingChanged);
        QSignalSpy finished(&editor, &ContactEditorBackend::finished);
        editor.contact()->setNote(u"Updated by the editor test"_s);
        editor.saveContactInAddressBook();
        QTRY_VERIFY_WITH_TIMEOUT(finished.count() > 0, 3000);
        QCOMPARE(savingChanged.count(), 2);
        QVERIFY(!editor.saving());
        QVERIFY(errors.isEmpty());
    }

    void editorRejectsMissingAddressBook()
    {
        ContactEditorBackend editor;
        QSignalSpy errors(&editor, &ContactEditorBackend::errorOccured);

        editor.contact()->setFormattedName(u"A contact without an address book"_s);
        editor.saveContactInAddressBook();

        QCOMPARE(errors.count(), 1);
        QCOMPARE(errors.first().first().toString(), u"No address book selected."_s);
        QVERIFY(!editor.saving());
    }

    void repositoryCanBeDestroyedWithSelectedCollection()
    {
        auto repository = std::make_unique<ContactRepository>();
        auto selectionModel = repository->findChild<QItemSelectionModel *>();
        QVERIFY(selectionModel);
        QTRY_VERIFY_WITH_TIMEOUT(selectionModel->model()->rowCount() > 0, 5000);
        selectionModel->select(selectionModel->model()->index(0, 0), QItemSelectionModel::Select);
        QVERIFY(selectionModel->hasSelection());

        repository.reset();
    }

    void editorMovesContactToAnotherAddressBook()
    {
        ContactEditorBackend editor;
        editor.setMode(ContactEditorBackend::EditMode);
        QSignalSpy loaded(&editor, &ContactEditorBackend::contactChanged);
        editor.setItem(m_contactItem);
        QVERIFY(loaded.wait(3000));
        editor.setDefaultAddressBook(m_otherContactCollection);

        QSignalSpy finished(&editor, &ContactEditorBackend::finished);
        editor.saveContactInAddressBook();
        QVERIFY(finished.wait(5000));
        QCOMPARE(editor.item().parentCollection().id(), m_otherContactCollection.id());

        auto moveBackJob = new Akonadi::ItemMoveJob(editor.item(), m_contactCollection, this);
        QSignalSpy moveBackResult(moveBackJob, &KJob::result);
        QVERIFY(moveBackResult.wait(5000));
        QVERIFY2(!moveBackJob->error(), qPrintable(moveBackJob->errorString()));
    }

    void groupEditorLoadsAndStoresGroup()
    {
        ContactGroupEditor editor;
        editor.setMode(ContactGroupEditor::EditMode);
        QSignalSpy nameChanged(&editor, &ContactGroupEditor::nameChanged);
        QSignalSpy errors(&editor, &ContactGroupEditor::errorOccured);
        editor.loadContactGroup(m_contactGroupItem);

        QVERIFY(nameChanged.wait(3000));
        QVERIFY(errors.isEmpty());
        QCOMPARE(editor.name(), u"KDE Friends"_s);
        QCOMPARE(editor.collectionId(), m_contactCollection.id());

        QSignalSpy savingChanged(&editor, &ContactGroupEditor::savingChanged);
        QSignalSpy finished(&editor, &ContactGroupEditor::finished);
        editor.setName(u"Updated KDE Friends"_s);
        QVERIFY(editor.saveContactGroup());
        QTRY_VERIFY_WITH_TIMEOUT(finished.count() > 0, 3000);
        QCOMPARE(savingChanged.count(), 2);
        QVERIFY(!editor.saving());
        QVERIFY(errors.isEmpty());
    }

    void editorsReportFetchErrors()
    {
        ContactEditorBackend contactEditor;
        contactEditor.setMode(ContactEditorBackend::EditMode);
        QSignalSpy contactErrors(&contactEditor, &ContactEditorBackend::errorOccured);
        contactEditor.setItem(Akonadi::Item(999999));
        QVERIFY(contactErrors.wait(3000));
        QCOMPARE(contactErrors.count(), 1);

        ContactGroupEditor groupEditor;
        groupEditor.setMode(ContactGroupEditor::EditMode);
        QSignalSpy groupErrors(&groupEditor, &ContactGroupEditor::errorOccured);
        groupEditor.loadContactGroup(Akonadi::Item(999998));
        QVERIFY(groupErrors.wait(3000));
        QCOMPARE(groupErrors.count(), 1);
    }

    void groupEditorRejectsMissingAddressBook()
    {
        ContactGroupEditor editor;
        QSignalSpy errors(&editor, &ContactGroupEditor::errorOccured);

        QVERIFY(!editor.saveContactGroup());
        QCOMPARE(errors.count(), 1);
        QCOMPARE(errors.first().first().toString(), u"No address book selected"_s);
        QVERIFY(!editor.saving());
    }

private:
    std::unique_ptr<ContactRepository> m_repository;
    Akonadi::Collection m_contactCollection;
    Akonadi::Collection m_otherContactCollection;
    Akonadi::Item m_contactItem;
    Akonadi::Item m_contactGroupItem;
};

QTEST_MAIN(EditorAndRepositoryTest)

#include "editorandrepositorytest.moc"
