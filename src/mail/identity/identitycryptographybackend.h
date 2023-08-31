// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementQuick/CryptographyBackendInterface>
#include <KIdentityManagement/Identity>
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
    KIdentityManagement::Identity identity() const override;
    void setIdentity(const KIdentityManagement::Identity &identity) override;

private:
    IdentityKeyListModel *m_openPgpKeyListModel = nullptr;
    IdentityKeyListModel *m_smimeKeyListModel = nullptr;
    KIdentityManagement::Identity m_identity;
};
