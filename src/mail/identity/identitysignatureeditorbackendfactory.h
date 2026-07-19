// SPDX-FileCopyrightText: 2026 Florian Richer <florian.richer@protonmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <KIdentityManagementQuick/SignatureEditorBackend>
#include <QObject>
#include <qqmlregistration.h>

class IdentitySignatureEditorBackendFactory : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(KIdentityManagementQuick::SignatureEditorBackend *signatureEditorBackend READ signatureEditorBackend CONSTANT)

public:
    explicit IdentitySignatureEditorBackendFactory() = default;

    Q_INVOKABLE KIdentityManagementQuick::SignatureEditorBackend *signatureEditorBackend() const;
};
