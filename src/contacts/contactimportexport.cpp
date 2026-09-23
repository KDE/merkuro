// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactimportexport.h"

#include <Akonadi/Collection>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemCreateJob>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <KContacts/Addressee>
#include <KContacts/VCardConverter>
#include <KLocalizedString>
#include <QAbstractItemModel>
#include <QDir>
#include <QFile>
#include <QItemSelectionModel>
#include <QSaveFile>
#include <QSet>

using namespace Qt::Literals::StringLiterals;

ContactImportExport::ContactImportExport(QObject *parent)
    : QObject(parent)
{
}

bool ContactImportExport::importInProgress() const
{
    return m_importInProgress;
}

void ContactImportExport::setImportInProgress(bool inProgress)
{
    if (m_importInProgress == inProgress) {
        return;
    }
    m_importInProgress = inProgress;
    Q_EMIT importInProgressChanged();
}

void ContactImportExport::importContacts(const QUrl &url, qint64 collectionId)
{
    if (m_importInProgress) {
        return;
    }
    setImportInProgress(true);
    m_itemsToImport.clear();
    m_pendingCreates = 0;
    m_importedCount = 0;
    m_importFailed = false;
    m_importError.clear();

    QFile file(url.toLocalFile());
    if (!url.isLocalFile() || !file.open(QIODevice::ReadOnly)) {
        setImportInProgress(false);
        Q_EMIT importFinished(false, 0, i18nc("@info", "Could not read the vCard file."));
        return;
    }

    KContacts::VCardConverter converter;
    const auto addressees = converter.parseVCards(file.readAll());
    if (addressees.isEmpty()) {
        setImportInProgress(false);
        Q_EMIT importFinished(false, 0, i18nc("@info", "The file did not contain any contacts."));
        return;
    }

    for (const auto &addressee : addressees) {
        Akonadi::Item item;
        item.setMimeType(KContacts::Addressee::mimeType());
        item.setPayload<KContacts::Addressee>(addressee);
        m_itemsToImport.append(item);
    }

    auto collectionJob = new Akonadi::CollectionFetchJob(Akonadi::Collection(collectionId), Akonadi::CollectionFetchJob::Base, this);
    connect(collectionJob, &KJob::result, this, [this, collectionJob] {
        if (collectionJob->error()) {
            setImportInProgress(false);
            Q_EMIT importFinished(false, 0, collectionJob->errorText());
            return;
        }

        const auto collections = collectionJob->collections();
        if (collections.isEmpty()) {
            setImportInProgress(false);
            Q_EMIT importFinished(false, 0, i18nc("@info", "The selected address book could not be found."));
            return;
        }
        const auto collection = collections.constFirst();
        if (!(collection.rights() & Akonadi::Collection::CanCreateItem) || !collection.contentMimeTypes().contains(KContacts::Addressee::mimeType())) {
            setImportInProgress(false);
            Q_EMIT importFinished(false, 0, i18nc("@info", "The selected address book does not allow contacts to be added."));
            return;
        }

        m_pendingCreates = m_itemsToImport.size();
        for (const auto &item : std::as_const(m_itemsToImport)) {
            auto createJob = new Akonadi::ItemCreateJob(item, collection, this);
            connect(createJob, &KJob::result, this, [this, createJob] {
                if (createJob->error()) {
                    m_importFailed = true;
                    if (m_importError.isEmpty()) {
                        m_importError = createJob->errorText();
                    }
                } else {
                    ++m_importedCount;
                }
                if (--m_pendingCreates == 0) {
                    finishImport();
                }
            });
        }
        m_itemsToImport.clear();
    });
}

void ContactImportExport::finishImport()
{
    setImportInProgress(false);
    Q_EMIT importFinished(!m_importFailed, m_importedCount, m_importError);
}

void ContactImportExport::exportContacts(const QUrl &url)
{
    if (!url.isLocalFile() || !m_model) {
        Q_EMIT exportFinished(false, 0, i18nc("@info", "Could not write the vCard file."));
        return;
    }

    QList<QModelIndex> indexes;
    if (m_selectionModel && !m_selectionModel->selectedIndexes().isEmpty()) {
        indexes = m_selectionModel->selectedIndexes();
    } else {
        indexes.reserve(m_model->rowCount());
        for (int row = 0; row < m_model->rowCount(); ++row) {
            indexes.append(m_model->index(row, 0));
        }
    }

    Akonadi::Item::List itemsToExport;
    QSet<qint64> exportedIds;
    for (const auto &index : std::as_const(indexes)) {
        const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.id() <= 0 || exportedIds.contains(item.id()) || !item.hasPayload<KContacts::Addressee>()) {
            continue;
        }
        exportedIds.insert(item.id());
        itemsToExport.append(item);
    }
    if (itemsToExport.isEmpty()) {
        Q_EMIT exportFinished(false, 0, i18nc("@info", "There are no contacts to export."));
        return;
    }

    writeContacts(url, itemsToExport);
}

void ContactImportExport::exportContact(const QUrl &url, qint64 itemId)
{
    if (!url.isLocalFile()) {
        Q_EMIT exportFinished(false, 0, i18nc("@info", "Could not write the vCard file."));
        return;
    }

    auto fetchJob = new Akonadi::ItemFetchJob(Akonadi::Item(itemId), this);
    fetchJob->fetchScope().fetchFullPayload();
    connect(fetchJob, &KJob::result, this, [this, fetchJob, url] {
        if (fetchJob->error() || fetchJob->items().isEmpty()) {
            Q_EMIT exportFinished(false, 0, fetchJob->errorText().isEmpty() ? i18nc("@info", "The contact could not be found.") : fetchJob->errorText());
            return;
        }
        writeContacts(url, fetchJob->items());
    });
}

void ContactImportExport::prepareContactForSharing(qint64 itemId)
{
    auto fetchJob = new Akonadi::ItemFetchJob(Akonadi::Item(itemId), this);
    fetchJob->fetchScope().fetchFullPayload();
    connect(fetchJob, &KJob::result, this, [this, fetchJob] {
        if (fetchJob->error() || fetchJob->items().isEmpty()) {
            Q_EMIT exportFinished(false, 0, fetchJob->errorText().isEmpty() ? i18nc("@info", "The contact could not be found.") : fetchJob->errorText());
            return;
        }

        const auto item = fetchJob->items().constFirst();
        if (!item.hasPayload<KContacts::Addressee>()) {
            Q_EMIT exportFinished(false, 0, i18nc("@info", "There are no contacts to export."));
            return;
        }

        KContacts::VCardConverter converter;
        const auto vCards = converter.createVCards({item.payload<KContacts::Addressee>()}, KContacts::VCardConverter::v3_0);
        m_sharedContactFile = std::make_unique<QTemporaryFile>(QDir::tempPath() + u"/merkuro-contact-XXXXXX.vcf"_s);
        m_sharedContactFile->setAutoRemove(true);
        if (!m_sharedContactFile->open() || m_sharedContactFile->write(vCards) != vCards.size() || !m_sharedContactFile->flush()) {
            m_sharedContactFile.reset();
            Q_EMIT exportFinished(false, 0, i18nc("@info", "Could not prepare the contact for sharing."));
            return;
        }
        Q_EMIT contactReadyToShare(QUrl::fromLocalFile(m_sharedContactFile->fileName()));
    });
}

void ContactImportExport::writeContacts(const QUrl &url, const Akonadi::Item::List &items)
{
    KContacts::Addressee::List addressees;
    for (const auto &item : items) {
        if (item.hasPayload<KContacts::Addressee>()) {
            addressees.append(item.payload<KContacts::Addressee>());
        }
    }
    if (addressees.isEmpty()) {
        Q_EMIT exportFinished(false, 0, i18nc("@info", "There are no contacts to export."));
        return;
    }

    KContacts::VCardConverter converter;
    const auto vCards = converter.createVCards(addressees, KContacts::VCardConverter::v3_0);
    QSaveFile file(url.toLocalFile());
    if (!file.open(QIODevice::WriteOnly) || file.write(vCards) != vCards.size() || !file.commit()) {
        Q_EMIT exportFinished(false, 0, i18nc("@info", "Could not write the vCard file."));
        return;
    }
    Q_EMIT exportFinished(true, addressees.size(), {});
}

#include "moc_contactimportexport.cpp"
