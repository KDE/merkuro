// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementQuick/CryptographyEditorBackend>
#include <QObject>
#include <qqmlregistration.h>

class IdentityCryptographyEditorBackendFactory : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(KIdentityManagementQuick::CryptographyEditorBackend *cryptoEditorBackend READ cryptoEditorBackend CONSTANT)

public:
    explicit IdentityCryptographyEditorBackendFactory() = default;

    Q_INVOKABLE KIdentityManagementQuick::CryptographyEditorBackend *cryptoEditorBackend() const;
};
