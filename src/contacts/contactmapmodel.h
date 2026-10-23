// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "contactlistproxymodel.h"

/// Contacts with coordinates, including coordinates stored on postal addresses.
class MERKURO_CONTACT_EXPORT ContactMapModel : public ContactListProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        CoordinateRole = BirthdayAgeRole + 1,
    };

    explicit ContactMapModel(QObject *parent = nullptr);
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

Q_SIGNALS:
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
};
