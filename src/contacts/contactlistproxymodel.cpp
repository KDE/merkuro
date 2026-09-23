// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactlistproxymodel.h"

#include <Akonadi/EntityTreeModel>
#include <KContacts/Addressee>
#include <QCollator>

namespace
{
QString displayText(const QString &display, const Akonadi::Item &item)
{
    if (!display.trimmed().isEmpty()) {
        return display;
    }
    if (item.mimeType() == KContacts::Addressee::mimeType() && item.hasPayload<KContacts::Addressee>()) {
        return item.payload<KContacts::Addressee>().preferredEmail();
    }
    return display;
}

QString sortText(const QModelIndex &index)
{
    const auto display = index.data(Qt::DisplayRole).toString();
    const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    return displayText(display, item);
}
}

ContactListProxyModel::ContactListProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);
    sort(0, Qt::AscendingOrder);
}

QVariant ContactListProxyModel::data(const QModelIndex &index, int role) const
{
    if (role == Qt::DisplayRole) {
        const auto display = QSortFilterProxyModel::data(index, role).toString();
        const auto item = QSortFilterProxyModel::data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        return displayText(display, item);
    }
    return QSortFilterProxyModel::data(index, role);
}

bool ContactListProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    const auto leftValue = sortText(left);
    const auto rightValue = sortText(right);
    const bool leftIsEmpty = leftValue.trimmed().isEmpty();
    const bool rightIsEmpty = rightValue.trimmed().isEmpty();
    if (leftIsEmpty != rightIsEmpty) {
        return !leftIsEmpty;
    }

    QCollator collator;
    collator.setCaseSensitivity(sortCaseSensitivity());
    collator.setNumericMode(true);
    return collator.compare(leftValue, rightValue) < 0;
}
