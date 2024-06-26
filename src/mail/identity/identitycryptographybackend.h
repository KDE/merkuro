// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementCore/Identity>
#include <KIdentityManagementQuick/CryptographyBackendInterface>
#include <QAbstractItemModel>

class IdentityKeyListModel;

class IdentityCryptographyBackend : public QObject, public KIdentityManagementQuick::CryptographyBackendInterface
{
    Q_OBJECT
    Q_INTERFACES(KIdentityManagementQuick::CryptographyBackendInterface)

public:
    explicit IdentityCryptographyBackend(QObject *parent = nullptr);

    Q_INVOKABLE QAbstractItemModel *openPgpKeyListModel() const override;
    Q_INVOKABLE QAbstractItemModel *smimeKeyListModel() const override;

protected:
    KIdentityManagementCore::Identity identity() const override;
    void setIdentity(const KIdentityManagementCore::Identity &identity) override;

private:
    IdentityKeyListModel *const m_openPgpKeyListModel;
    IdentityKeyListModel *const m_smimeKeyListModel;
    KIdentityManagementCore::Identity m_identity;
};
