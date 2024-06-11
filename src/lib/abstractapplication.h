// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once

#include <KirigamiAbstractApplication>
#include <QObject>
#include <QSortFilterProxyModel>

class AbstractApplication : public KirigamiAbstractApplication
{
    Q_OBJECT

public:
    explicit AbstractApplication(QObject *parent = nullptr);

Q_SIGNALS:
    void openSettings();
    void openTagManager();

protected:
    void setupActions() override;
};
