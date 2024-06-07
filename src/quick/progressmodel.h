// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QObject>

namespace Akonadi::Quick
{
class ProgressModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit ProgressModel(QObject *parent = nullptr);
};
}