// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "kleoquickplugin.h"

#include <Libkleo/KeyListSortFilterProxyModel>
#include <QQmlEngine>

void KleoQuickPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kleo"));

    qmlRegisterType<Kleo::KeyListSortFilterProxyModel>("org.kde.kleo", 1, 0, "KeyListSortFilterProxyModel");
}
