// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include "identitywrapper.h"

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{

IdentityWrapper::IdentityWrapper(Identity &identity)
    : m_identity(identity)
{
}

}
}