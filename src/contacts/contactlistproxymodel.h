// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/Item>
#include <QDate>
#include <QHash>
#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

#include "merkuro_contact_export.h"

class MERKURO_CONTACT_EXPORT ContactListProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Role {
        BirthdaySectionRole = Qt::UserRole + 100,
        BirthdayDateRole,
        BirthdayAgeRole,
    };

    explicit ContactListProxyModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    void setBirthdays(QHash<Akonadi::Item::Id, QDate> birthdays);
    void setBirthdaysOnly(bool enabled);
    [[nodiscard]] static QDate nextBirthday(const QDate &birthday, const QDate &today);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    QHash<Akonadi::Item::Id, QDate> m_birthdays;
    bool m_birthdaysOnly = false;
};
