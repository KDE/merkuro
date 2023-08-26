// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#include "identitypgpkeylistmodel.h"

IdentityPGPKeyListModel::IdentityPGPKeyListModel(QObject *parent)
    : KIdentityManagement::Quick::AbstractKeyListModel(parent)
{
}
