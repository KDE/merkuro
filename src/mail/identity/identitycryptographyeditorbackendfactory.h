// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <KIdentityManagement/CryptographyEditorBackend>
#include <QObject>

class IdentityCryptographyEditorBackendFactory : public QObject
{
    Q_OBJECT

public:
    explicit IdentityCryptographyEditorBackendFactory() = default;

    Q_INVOKABLE static KIdentityManagement::Quick::CryptographyEditorBackend *newCryptoEditorBackend();
};
