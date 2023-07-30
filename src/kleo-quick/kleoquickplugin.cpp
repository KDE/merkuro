// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "kleoquickplugin.h"

#include <QQmlEngine>

#include "keycomboboxmodel.h"

void KleoQuickPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kleo"));

    qmlRegisterType<Kleo::Quick::KeyComboBoxModel>("org.kde.kleo", 1, 0, "KeyComboBoxModel");
}
