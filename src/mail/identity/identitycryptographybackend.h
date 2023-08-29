// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementCore/CryptographyBackendInterface>
#include <KIdentityManagementCore/Identity>
#include <QAbstractItemModel>

class IdentityKeyListModel;

class IdentityCryptographyBackend : public QObject, public KIdentityManagementCore::Quick::CryptographyBackendInterface
{
    Q_OBJECT
    Q_INTERFACES(KIdentityManagementCore::Quick::CryptographyBackendInterface)

public:
    explicit IdentityCryptographyBackend(QObject *parent = nullptr);

    Q_INVOKABLE QAbstractItemModel *openPgpKeyListModel() const override;
    Q_INVOKABLE QAbstractItemModel *smimeKeyListModel() const override;

protected:
    KIdentityManagementCore::Identity identity() const override;
    void setIdentity(const KIdentityManagementCore::Identity &identity) override;

private:
    IdentityKeyListModel *m_openPgpKeyListModel = nullptr;
    IdentityKeyListModel *m_smimeKeyListModel = nullptr;
    KIdentityManagementCore::Identity m_identity;
};
