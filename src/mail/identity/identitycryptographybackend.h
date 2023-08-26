// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <KIdentityManagement/AbstractCryptographyBackend>

namespace KIdentityManagement
{
namespace Quick
{
class AbstractKeyListModel;
}
}

class IdentityCryptographyBackend : public KIdentityManagement::Quick::AbstractCryptographyBackend
{
    Q_OBJECT

public:
    IdentityCryptographyBackend();

    KIdentityManagement::Quick::AbstractKeyListModel *openPgpKeyListModel() const override;
    KIdentityManagement::Quick::AbstractKeyListModel *smimeKeyListModel() const override;

private:
    KIdentityManagement::Quick::AbstractKeyListModel *m_openPgpKeyListModel = nullptr;
    KIdentityManagement::Quick::AbstractKeyListModel *m_smimeKeyListModel = nullptr;
};
