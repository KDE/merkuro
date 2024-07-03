// SPDX-FileCopyrightText: 2023 g10 Code GmbH
// SPDX-FileContributor: Carl Schwan <carl.schwan@gnupg.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <Akonadi/Item>
#include <KMime/Message>
#include <QObject>
#include <qqmlregistration.h>

class MessageLoader : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem NOTIFY itemChanged)
    Q_PROPERTY(KMime::Message::Ptr message READ message NOTIFY messageChanged)

public:
    explicit MessageLoader(QObject *parent = nullptr);

    [[nodiscard]] Akonadi::Item item() const;
    void setItem(const Akonadi::Item &item);
    [[nodiscard]] KMime::Message::Ptr message() const;

Q_SIGNALS:
    void itemChanged();
    void messageChanged();

private:
    Akonadi::Item m_item;
    KMime::Message::Ptr m_message;
};
