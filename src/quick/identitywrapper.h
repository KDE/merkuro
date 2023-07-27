// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <KIdentityManagement/Identity>
#include <QObject>

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{
class IdentityWrapper : public QObject
{
    Q_OBJECT

public:
    explicit IdentityWrapper(Identity &identity);

private:
    Identity m_identity;
};
}
}
