// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/AgentInstance>
#include <qqmlregistration.h>

struct AgentDataChange {
    Q_GADGET
    Q_PROPERTY(QString instanceId MEMBER instanceId)
    Q_PROPERTY(int status MEMBER status)

    QString instanceId;
    int status;
};

class AgentConfiguration : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Akonadi::AgentFilterProxyModel *availableAgents READ availableAgents NOTIFY availableAgentsChanged)
    Q_PROPERTY(Akonadi::AgentFilterProxyModel *runningAgents READ runningAgents NOTIFY runningAgentsChanged)
    Q_PROPERTY(QStringList mimetypes READ mimetypes WRITE setMimetypes NOTIFY mimetypesChanged)
public:
    enum AgentStatuses {
        Idle = Akonadi::AgentInstance::Idle,
        Running = Akonadi::AgentInstance::Running,
        Broken = Akonadi::AgentInstance::Broken,
        NotConfigured = Akonadi::AgentInstance::NotConfigured,
    };
    Q_ENUM(AgentStatuses)

    explicit AgentConfiguration(QObject *parent = nullptr);
    ~AgentConfiguration() override;

    Akonadi::AgentFilterProxyModel *availableAgents();
    Akonadi::AgentFilterProxyModel *runningAgents();
    [[nodiscard]] QStringList mimetypes() const;
    void setMimetypes(const QStringList &mimetypes);

    Q_INVOKABLE void createNew(int index);
    Q_INVOKABLE void edit(int index);
    Q_INVOKABLE void editIdentifier(const QString &resourceIdentifier);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void removeIdentifier(const QString &resourceIdentifier);
    Q_INVOKABLE void restart(int index);
    Q_INVOKABLE void restartIdentifier(const QString &resourceIdentifier);
    Q_INVOKABLE bool isRemovable(int index);

Q_SIGNALS:
    void agentProgressChanged(const Akonadi::AgentInstance &instance);
    void mimetypesChanged();
    void runningAgentsChanged();
    void availableAgentsChanged();
    void errorOccurred(const QString &error);

private:
    void setupEdit(Akonadi::AgentInstance instance);
    void setupRemove(const Akonadi::AgentInstance &instance);
    void setupRestart(Akonadi::AgentInstance instance);

    Akonadi::AgentFilterProxyModel *m_runningAgents = nullptr;
    Akonadi::AgentFilterProxyModel *m_availableAgents = nullptr;
    QStringList m_mimetypes;
};
