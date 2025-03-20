// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <qqmlregistration.h>

#include <Akonadi/Item>

namespace Akonadi
{
namespace Quick
{
class ItemForeign
{
    Q_GADGET
    QML_FOREIGN(Akonadi::Item)
    QML_VALUE_TYPE(item)
};
}
}