// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <MessageList/Aggregation>
#include <QQmlEngine>

struct MessageListAggregationForeign {
    Q_GADGET
    QML_FOREIGN(MessageList::Core::Aggregation)
    QML_NAMED_ELEMENT(MessageListAggregation)
    QML_UNCREATABLE("This type only provides MessageList threading enum values")
};
