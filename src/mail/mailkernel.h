// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <MailCommon/MailInterfaces>

namespace Akonadi
{
class AgentInstance;
class EntityTreeModel;
class EntityMimeTypeFilterModel;
}

namespace MailCommon
{
class FolderCollectionMonitor;
}

/**
 * @short Central point of coordination in Merkuro Mail
 *
 * The MailKernel class represents the core of Merkuro Mail, where the different parts
 * come together and are coordinated. It is currently also the class which exports
 * Merkuro Mail's main D-BUS interfaces.
 *
 * The kernel is responsible for creating various
 * (singleton) objects such as the identity manager and the message sender.
 *
 * The kernel also creates an Akonadi Session, Monitor and EntityTreeModel. These
 * are shared so that other objects in Merkuro Mail have access to it. Having only one EntityTreeModel
 * instead of many reduces the overall communication with the Akonadi server.
 */
class MailKernel : public QObject, public MailCommon::IKernel, public MailCommon::ISettings, public MailCommon::IFilter
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.pim.merkuro.mail")

public:
    static MailKernel &self();

    // IKernel
    KIdentityManagementCore::IdentityManager *identityManager() override;
    MessageComposer::MessageSender *msgSender() override;

    // ISettings
    Akonadi::EntityMimeTypeFilterModel *collectionModel() const override;
    KSharedConfig::Ptr config() override;
    void syncConfig() override;
    MailCommon::JobScheduler *jobScheduler() const override;
    Akonadi::ChangeRecorder *folderCollectionMonitor() const override;
    void updateSystemTray() override;

    // IFilter
    void openFilterDialog(bool createDummyFilter = true) override;
    void createFilter(const QByteArray &field, const QString &value) override;

    [[nodiscard]] qreal closeToQuotaThreshold() override;
    [[nodiscard]] bool excludeImportantMailFromExpiry() override;
    [[nodiscard]] QStringList customTemplates() override;
    [[nodiscard]] Akonadi::Collection::Id lastSelectedFolder() override;
    void setLastSelectedFolder(Akonadi::Collection::Id col) override;
    [[nodiscard]] bool showPopupAfterDnD() override;
    void expunge(Akonadi::Collection::Id id, bool sync) override;

public Q_SLOTS:
    void slotInstanceStatusChanged(const Akonadi::AgentInstance &instance);

Q_SIGNALS:
    void errorOccurred(const QString &error);

private:
    explicit MailKernel(QObject *parent = nullptr);
    ~MailKernel() override;

    KSharedConfigPtr mConfig;
    KIdentityManagementCore::IdentityManager *const mIdentityManager = nullptr;
    MessageComposer::MessageSender *const mMessageSender = nullptr;
    MailCommon::FolderCollectionMonitor *mFolderCollectionMonitor = nullptr;
    Akonadi::EntityTreeModel *mEntityTreeModel = nullptr;
    Akonadi::EntityMimeTypeFilterModel *mCollectionModel = nullptr;
};
