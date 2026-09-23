// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactlistproxymodel.h"

#include <Akonadi/EntityTreeModel>
#include <KContacts/Addressee>
#include <KContacts/PhoneNumber>
#include <QCollator>
#include <algorithm>

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

bool ContactListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent)) {
        return true;
    }

    const auto expression = filterRegularExpression();
    if (expression.pattern().isEmpty()) {
        return true;
    }

    const auto sourceIndex = sourceModel()->index(sourceRow, filterKeyColumn(), sourceParent);
    const auto item = sourceIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
    if (!item.hasPayload<KContacts::Addressee>()) {
        return false;
    }

    const auto addressee = item.payload<KContacts::Addressee>();
    QStringList searchableFields{
        addressee.formattedName(),
        addressee.realName(),
        addressee.givenName(),
        addressee.additionalName(),
        addressee.familyName(),
        addressee.nickName(),
        addressee.organization(),
        addressee.preferredEmail(),
    };
    for (const auto &email : addressee.emailList()) {
        searchableFields.append(email.mail());
    }
    for (const auto &phoneNumber : addressee.phoneNumbers()) {
        searchableFields.append(phoneNumber.number());
    }

    return std::any_of(searchableFields.cbegin(), searchableFields.cend(), [&expression](const QString &field) {
        return expression.match(field).hasMatch();
    });
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
