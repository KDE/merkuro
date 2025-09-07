// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailmanager.h"

// Akonadi
#include "merkuro_mail_debug.h"

#include "mailkernel.h"
#include "sortedcollectionproxymodel.h"

#include <Akonadi/AgentManager>
#include <Akonadi/ChangeRecorder>
#include <Akonadi/CollectionCreateJob>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemFetchJob>
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
#include <KMbox/MBox>
#include <KMime/Message>
#include <MailCommon/FolderCollectionMonitor>
#include <MailCommon/MailKernel>
#include <MailCommon/MailUtil>
#include <QApplication>
#include <QLoggingCategory>
#include <QPointer>

MailManager::MailManager(QObject *parent)
    : QObject(parent)
    , m_loading(true)
{
    using namespace Akonadi;

    MailKernel::self();

    connect(&MailKernel::self(), &MailKernel::errorOccurred, this, &MailManager::errorOccurred);

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
    m_entityTreeModel = new Akonadi::EntityTreeModel(folderCollectionMonitor->monitor(), this);
    m_entityTreeModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::LazyPopulation);
    connect(m_entityTreeModel, &Akonadi::EntityTreeModel::errorOccurred, this, &MailManager::errorOccurred);

    auto foldersModel = new Akonadi::CollectionFilterProxyModel(this);
    foldersModel->setSourceModel(m_entityTreeModel);
    foldersModel->addMimeTypeFilter(KMime::Message::mimeType());

    m_foldersModel = new MailCommon::EntityCollectionOrderProxyModel(this);
    m_foldersModel->setSourceModel(foldersModel);
    m_foldersModel->setFilterCaseSensitivity(Qt::CaseInsensitive);
    KConfigGroup grp(KernelIf->config(), QStringLiteral("CollectionTreeOrder"));
    m_foldersModel->setOrderConfig(grp);
    m_foldersModel->sort(0, Qt::AscendingOrder);

    // Setup selection model
    m_collectionSelectionModel = new QItemSelectionModel(m_foldersModel);

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
    KConfigGroup readerConfig(KernelIf->config(), QStringLiteral("AccountOrder"));
    QStringList listOrder;
    if (readerConfig.readEntry("EnableAccountOrder", true)) {
        listOrder = readerConfig.readEntry("order", QStringList());
    }
    m_foldersModel->setTopLevelOrder(listOrder);
}

void MailManager::saveConfig()
{
}

QItemSelectionModel *MailManager::collectionSelectionModel() const
{
    return m_collectionSelectionModel;
}

Akonadi::EntityTreeModel *MailManager::entryTreeModel() const
{
    return m_entityTreeModel;
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
                qCWarning(MERKURO_MAIL_LOG) << "Error occurred deleting collection: " << job->errorString();
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

void MailManager::saveMail(const QUrl &fileUrl, const Akonadi::Item &item)
{
    const auto filename = fileUrl.toLocalFile();

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    connect(job, &Akonadi::ItemFetchJob::result, this, [filename](KJob *job) {
        const auto *fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        const auto items = fetchJob->items();
        if (items.isEmpty()) {
            qWarning() << "Error occurred: empty fetch job";
            return;
        }
        const auto item = items.at(0);
        if (!item.hasPayload()) {
            qCCritical(MERKURO_MAIL_LOG) << "Error occurred: error parsing mail";
            return;
        }

        const auto message = item.payload<KMime::Message::Ptr>();
        KMBox::MBox mbox;
        if (!mbox.load(filename)) {
            qCWarning(MERKURO_MAIL_LOG) << "Error occurred: error creating file";
        }
        mbox.appendMessage(message);

        if (!mbox.save()) {
            qCWarning(MERKURO_MAIL_LOG) << "Error occurred: error saving mail";
        }
    });
}

void MailManager::checkMail()
{
    auto agents = MailCommon::Util::agentInstances();
    for (auto &agent : agents) {
        if (!agent.isOnline()) {
            agent.setIsOnline(true);
        }
        agent.synchronize();
    }
}

#include "moc_mailmanager.cpp"
