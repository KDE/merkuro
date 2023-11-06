// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailmanager.h"

// Akonadi
#include "merkuro_mail_debug.h"

#include "mailkernel.h"
#include <Akonadi/AgentManager>
#include <Akonadi/ChangeRecorder>
#include <Akonadi/CollectionCreateJob>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemMoveJob>
#include <Akonadi/MessageModel>
#include <Akonadi/Monitor>
#include <Akonadi/SelectionProxyModel>
#include <Akonadi/ServerManager>
#include <Akonadi/Session>
#include <KConfigGroup>
#include <KDescendantsProxyModel>
#include <KLocalizedString>
#include <KMime/Message>
#include <MailCommon/EntityCollectionOrderProxyModel>
#include <MailCommon/FolderCollectionMonitor>
#include <MailCommon/MailKernel>
#include <QApplication>
#include <QLoggingCategory>
#include <QPointer>
#include <sortedcollectionproxymodel.h>

MailManager::MailManager(QObject *parent)
    : QObject(parent)
    , m_loading(true)
{
    using namespace Akonadi;

    MailKernel::self();

    //                              mailModel
    //                                  ^
    //                                  |
    //                              itemModel
    //                                  |
    //                              flatModel
    //                                  |
    //  descendantsProxyModel ------> selectionModel
    //           ^                      ^
    //           |                      |
    //  collectionFilter                |
    //            \__________________treemodel

    m_session = new Session(QByteArrayLiteral("KMailManager Kernel ETM"), this);
    auto folderCollectionMonitor = new MailCommon::FolderCollectionMonitor(m_session, this);

    // setup collection model
    auto treeModel = new Akonadi::EntityTreeModel(folderCollectionMonitor->monitor(), this);
    treeModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::LazyPopulation);

    auto foldersModel = new Akonadi::CollectionFilterProxyModel(this);
    foldersModel->setSourceModel(treeModel);
    foldersModel->addMimeTypeFilter(KMime::Message::mimeType());

    m_foldersModel = new MailCommon::EntityCollectionOrderProxyModel(this);
    m_foldersModel->setSourceModel(foldersModel);
    m_foldersModel->setFilterCaseSensitivity(Qt::CaseInsensitive);
    KConfigGroup grp(KernelIf->config(), QLatin1String("CollectionTreeOrder"));
    m_foldersModel->setOrderConfig(grp);
    m_foldersModel->sort(0, Qt::AscendingOrder);

    // Setup selection model
    m_collectionSelectionModel = new QItemSelectionModel(m_foldersModel);
    connect(m_collectionSelectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
        Q_UNUSED(deselected)
        const auto indexes = selected.indexes();
        if (indexes.count()) {
            QString name;
            QModelIndex index = indexes[0];
            while (index.isValid()) {
                if (name.isEmpty()) {
                    name = index.data(Qt::DisplayRole).toString();
                } else {
                    name = index.data(Qt::DisplayRole).toString() + QLatin1String(" / ") + name;
                }
                index = index.parent();
            }
            m_selectedFolderName = name;
            Q_EMIT selectedFolderNameChanged();
        }
    });
    auto selectionModel = new SelectionProxyModel(m_collectionSelectionModel, this);
    selectionModel->setSourceModel(treeModel);
    selectionModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    // Setup mail model
    auto folderFilterModel = new EntityMimeTypeFilterModel(this);
    folderFilterModel->setSourceModel(selectionModel);
    folderFilterModel->setHeaderGroup(EntityTreeModel::ItemListHeaders);
    folderFilterModel->addMimeTypeInclusionFilter(KMime::Message::mimeType());
    folderFilterModel->addMimeTypeExclusionFilter(Collection::mimeType());

    // Proxy for QML roles
    m_folderModel = new MailModel(this);
    m_folderModel->setSourceModel(folderFilterModel);

    if (Akonadi::ServerManager::isRunning()) {
        m_loading = false;
    } else {
        connect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged, this, [this](Akonadi::ServerManager::State state) {
            if (state == Akonadi::ServerManager::State::Broken) {
                qApp->exit(-1);
                return;
            }
            bool loading = state != Akonadi::ServerManager::State::Running;
            if (loading == m_loading) {
                return;
            }
            m_loading = loading;
            Q_EMIT loadingChanged();
            disconnect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged, this, nullptr);
        });
    }
    CommonKernel->initFolders();

    loadConfig();
}

void MailManager::loadConfig()
{
    KConfigGroup readerConfig(KernelIf->config(), QLatin1String("AccountOrder"));
    QStringList listOrder;
    if (readerConfig.readEntry("EnableAccountOrder", true)) {
        listOrder = readerConfig.readEntry("order", QStringList());
    }
    m_foldersModel->setTopLevelOrder(listOrder);
}

void MailManager::saveConfig()
{
}

MailModel *MailManager::folderModel() const
{
    return m_folderModel;
}

void MailManager::loadMailCollection(const QModelIndex &modelIndex)
{
    if (!modelIndex.isValid()) {
        return;
    }

    m_collectionSelectionModel->select(modelIndex, QItemSelectionModel::ClearAndSelect);
}

bool MailManager::loading() const
{
    return m_loading;
}

MailCommon::EntityCollectionOrderProxyModel *MailManager::foldersModel() const
{
    return m_foldersModel;
}

Akonadi::Session *MailManager::session() const
{
    return m_session;
}

QString MailManager::selectedFolderName() const
{
    return m_selectedFolderName;
}

void MailManager::moveToTrash(Akonadi::Item item)
{
    auto collection = qvariant_cast<Akonadi::Collection>(
        foldersModel()->data(m_collectionSelectionModel->selection().indexes()[0], Akonadi::EntityTreeModel::CollectionRole));
    auto trash = CommonKernel->trashCollectionFromResource(collection);
    if (!trash.isValid()) {
        trash = CommonKernel->trashCollectionFolder();
    }
    new Akonadi::ItemMoveJob(item, trash);
}

void MailManager::updateCollection(const QModelIndex &index)
{
    const auto collection = foldersModel()->data(index, Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
    Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
}

void MailManager::addCollection(const QModelIndex &index, const QVariant &name)
{
    const auto parentCollection = foldersModel()->data(index, Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
    const auto collection = new Akonadi::Collection();
    collection->setParentCollection(parentCollection);
    collection->setName(name.toString());
    collection->setContentMimeTypes({QStringLiteral("message/rfc822")});

    const auto job = new Akonadi::CollectionCreateJob(*collection);
    connect(job, SIGNAL(result(KJob *)), job, SLOT(slotResult(KJob *)));
}

void MailManager::deleteCollection(const QModelIndex &index)
{
    const auto collection = foldersModel()->data(index, Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // delete contents
        const auto job = new Akonadi::CollectionDeleteJob(collection);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(merkuro_MAIL_LOG) << "Error occured deleting collection: " << job->errorString();
            }
        });
        return;
    }

    // deletes agent but not the contents
    const auto instance = Akonadi::AgentManager::self()->instance(collection.resource());
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

void MailManager::editCollection(const QModelIndex &index)
{
    const auto collection = foldersModel()->data(index, Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
    QPointer<Akonadi::CollectionPropertiesDialog> dialog = new Akonadi::CollectionPropertiesDialog(collection);
    dialog->setWindowTitle(i18nc("@title:window", "Account Configuration: %1", collection.name()));
    dialog->show();
}

QString MailManager::resourceIdentifier(const QModelIndex &index)
{
    const auto collection = foldersModel()->data(index, Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
    return collection.resource();
}

#include "moc_mailmanager.cpp"
