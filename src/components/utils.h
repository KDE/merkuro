// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QItemSelection>
#include <QObject>
#include <qqmlregistration.h>

class Utils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Utils(QObject *parent = nullptr);

    Q_INVOKABLE QModelIndexList indexesFromSelection(const QItemSelection &selection);
};
