// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/AgentInstance>
#include <QObject>
#include <qqmlregistration.h>

namespace Akonadi
{
namespace Quick
{
class AgentInstanceForeign
{
    Q_GADGET
    QML_VALUE_TYPE(agentInstance)
    QML_FOREIGN(Akonadi::AgentInstance)
};
}
}
