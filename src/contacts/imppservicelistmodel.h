// SPDX-FileCopyrightText: 2026 Yuki Joou <yukijoou@kemonomimi.gay>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "merkuro_contact_export.h"

#include <QAbstractListModel>
#include <qqmlregistration.h>

/*
 * Wrapper model around Kcontacts::Impp::serviceTypes()
 */
class MERKURO_CONTACT_EXPORT ImppServiceListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum ExtraRole {
        ServiceTypeRole = Qt::UserRole,
    };

    explicit ImppServiceListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
};
