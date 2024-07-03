// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/Collection>
#include <QObject>
#include <qqmlregistration.h>

class MailCollectionHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Q_INVOKABLE qint64 unreadCount(const Akonadi::Collection &collection);
};
