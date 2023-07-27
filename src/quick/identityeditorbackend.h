// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KIdentityManagement/IdentityManager>
#include <QObject>

#include "identitywrapper.h"

using namespace KIdentityManagement;

namespace Akonadi
{
namespace Quick
{

class IdentityEditorBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(IdentityWrapper *identity READ identity NOTIFY identityChanged NOTIFY modeChanged)
    Q_PROPERTY(uint identityUiod READ identityUiod WRITE setIdentityUiod NOTIFY identityChanged)

public:
    enum Mode { CreateMode, EditMode };
    Q_ENUM(Mode);

    explicit IdentityEditorBackend() = default;

    Q_REQUIRED_RESULT Mode mode() const;
    void setMode(Mode mode);

    Q_REQUIRED_RESULT IdentityWrapper *identity() const;
    void setIdentity(IdentityWrapper *identity);

    Q_REQUIRED_RESULT uint identityUiod() const;
    void setIdentityUiod(uint identityUiod);

Q_SIGNALS:
    void modeChanged();
    void identityChanged();

private:
    IdentityManager *const m_identityManager = IdentityManager::self();
    IdentityWrapper *m_identity = nullptr;
    Mode m_mode = CreateMode;
};
}
}