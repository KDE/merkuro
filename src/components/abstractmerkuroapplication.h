// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once

#include <AbstractKirigamiApplication>
#include <KSharedConfig>
#include <QObject>
#include <QSortFilterProxyModel>
#include <merkurocomponents_export.h>

class MERKUROCOMPONENTS_EXPORT AbstractMerkuroApplication : public AbstractKirigamiApplication
{
    Q_OBJECT
    QML_ELEMENT
    // QML_UNCREATABLE("Abstract class")

    /// This property holds whether the menubar is visible.
    Q_PROPERTY(bool menubarVisible READ menubarVisible NOTIFY menubarVisibleChanged)

public:
    explicit AbstractMerkuroApplication(QObject *parent = nullptr);
    void toggleMenubar();

    bool menubarVisible() const;

Q_SIGNALS:
    void openSettings();
    void openTagManager();
    void menubarVisibleChanged();

protected:
    void setupActions() override;

private:
    KSharedConfig::Ptr m_shared;
};
