// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <KIdentityManagement/AbstractKeyListModel>

class IdentityPGPKeyListModel : public KIdentityManagement::Quick::AbstractKeyListModel
{
    Q_OBJECT

public:
    explicit IdentityPGPKeyListModel(QObject *parent = nullptr);
};
