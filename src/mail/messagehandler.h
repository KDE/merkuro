// SPDX-FileCopyrightText: 2023 Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KMime/Message>
#include <QObject>
#include <QUrl>
#include <qqmlintegration.h>

class MessageHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    Q_INVOKABLE void open(const QUrl &file);

Q_SIGNALS:
    void messageOpened(std::shared_ptr<KMime::Message> message);
};
