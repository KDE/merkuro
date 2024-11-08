// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once

#include "merkuro_contact_export.h"
#include <abstractmerkuroapplication.h>

class QQuickWindow;

class MERKURO_CONTACT_EXPORT ContactApplication : public AbstractMerkuroApplication
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit ContactApplication(QObject *parent = nullptr);

    QList<KirigamiActionCollection *> actionCollections() const override;

    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);

Q_SIGNALS:
    void createNewContact();
    void createNewContactGroup();
    void refreshAll();
    void showMenubarChanged(bool state);

private:
    void setupActions() override;
    KirigamiActionCollection *mContactCollection = nullptr;
};
