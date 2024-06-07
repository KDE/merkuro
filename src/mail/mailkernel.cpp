// SPDX-FileCopyrightText: 2018 Daniel Vrátil <dvratil@kde.org>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "mailkernel.h"

#include <Akonadi/AgentManager>
#include <Akonadi/ChangeRecorder>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/Session>

#include <KIdentityManagementCore/IdentityManager>

#include <KSharedConfig>

#include <Libkdepim/ProgressManager>

#include <MailCommon/FolderCollectionMonitor>
#include <MailCommon/MailKernel>
#include <MailCommon/MailUtil>

#include <MessageComposer/AkonadiSender>

#include <PimCommonAkonadi/ProgressManagerAkonadi>

static MailKernel *mySelf = nullptr;

MailKernel &MailKernel::self()
{
    static MailKernel instance;
    return instance;
}

MailKernel::MailKernel(QObject *parent)
    : QObject(parent)
    , mConfig(KSharedConfig::openConfig(QStringLiteral("merkuromailrc")))
    , mIdentityManager(new KIdentityManagementCore::IdentityManager(true, this))
    , mMessageSender(new MessageComposer::AkonadiSender(this))
{
    auto session = new Akonadi::Session("Merkuro Mail Kernel ETM", this);

    mFolderCollectionMonitor = new MailCommon::FolderCollectionMonitor(session, this);

    mEntityTreeModel = new Akonadi::EntityTreeModel(folderCollectionMonitor(), this);
    mEntityTreeModel->setListFilter(Akonadi::CollectionFetchScope::Enabled);
    mEntityTreeModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::LazyPopulation);

    mCollectionModel = new Akonadi::EntityMimeTypeFilterModel(this);
    mCollectionModel->setSourceModel(mEntityTreeModel);
    mCollectionModel->addMimeTypeInclusionFilter(Akonadi::Collection::mimeType());
    mCollectionModel->setHeaderGroup(Akonadi::EntityTreeModel::CollectionTreeHeaders);
    mCollectionModel->setDynamicSortFilter(true);
    mCollectionModel->setSortCaseSensitivity(Qt::CaseInsensitive);

    CommonKernel->registerKernelIf(this);
    CommonKernel->registerSettingsIf(this);
    CommonKernel->registerFilterIf(this);

    connect(Akonadi::AgentManager::self(), &Akonadi::AgentManager::instanceStatusChanged, this, &MailKernel::slotInstanceStatusChanged);
}

MailKernel::~MailKernel()
{
    CommonKernel->registerKernelIf(nullptr);
    CommonKernel->registerSettingsIf(nullptr);
    CommonKernel->registerFilterIf(nullptr);
}

KIdentityManagementCore::IdentityManager *MailKernel::identityManager()
{
    return mIdentityManager;
}

MessageComposer::MessageSender *MailKernel::msgSender()
{
    return mMessageSender;
}

Akonadi::EntityMimeTypeFilterModel *MailKernel::collectionModel() const
{
    return mCollectionModel;
}

KSharedConfig::Ptr MailKernel::config()
{
    return mConfig;
}

void MailKernel::syncConfig()
{
    Q_ASSERT(false);
}

MailCommon::JobScheduler *MailKernel::jobScheduler() const
{
    Q_ASSERT(false);
    return nullptr;
}

Akonadi::ChangeRecorder *MailKernel::folderCollectionMonitor() const
{
    return mFolderCollectionMonitor->monitor();
}

void MailKernel::updateSystemTray()
{
    Q_ASSERT(false);
}

bool MailKernel::showPopupAfterDnD()
{
    return false;
}

qreal MailKernel::closeToQuotaThreshold()
{
    return 80;
}

QStringList MailKernel::customTemplates()
{
    Q_ASSERT(false);
    return {};
}

bool MailKernel::excludeImportantMailFromExpiry()
{
    Q_ASSERT(false);
    return true;
}

Akonadi::Collection::Id MailKernel::lastSelectedFolder()
{
    Q_ASSERT(false);
    return Akonadi::Collection::Id();
}

void MailKernel::setLastSelectedFolder(Akonadi::Collection::Id col)
{
    Q_UNUSED(col)
}

void MailKernel::expunge(Akonadi::Collection::Id id, bool sync)
{
    Akonadi::Collection col(id);
    if (col.isValid()) {
        mFolderCollectionMonitor->expunge(Akonadi::Collection(col), sync);
    }
}

void MailKernel::openFilterDialog(bool createDummyFilter)
{
}

void MailKernel::createFilter(const QByteArray &field, const QString &value)
{
}

void MailKernel::slotInstanceStatusChanged(const Akonadi::AgentInstance &instance)
{
    const auto isMailInstance =
        instance.identifier() == QStringLiteral("akonadi_mailfilter_agent") || MailCommon::Util::agentInstances(true).contains(instance);

    if (!isMailInstance) {
        return;
    }

    if (instance.status() == Akonadi::AgentInstance::Running) {
        // Creating a progress item twice is ok, it will simply return the already existing item
        const auto progress = PimCommon::ProgressManagerAkonadi::createProgressItem(nullptr,
                                                                                    instance,
                                                                                    instance.identifier(),
                                                                                    instance.name(),
                                                                                    instance.statusMessage(),
                                                                                    true,
                                                                                    KPIM::ProgressItem::Unknown);
        progress->setProperty("AgentIdentifier", instance.identifier());
    }
}

#include "moc_mailkernel.cpp"
