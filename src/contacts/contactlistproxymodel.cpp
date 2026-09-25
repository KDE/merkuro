// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactlistproxymodel.h"

#include <Akonadi/EntityTreeModel>
#include <KContacts/Addressee>
#include <KContacts/PhoneNumber>
#include <KLocalizedString>
#include <QCollator>
#include <QDateTime>
#include <QLocale>
#include <QTimer>
#include <algorithm>

using namespace Qt::Literals::StringLiterals;

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

    auto midnightTimer = new QTimer(this);
    midnightTimer->setSingleShot(true);
    connect(midnightTimer, &QTimer::timeout, this, [this, midnightTimer]() {
        if (m_birthdaysOnly) {
            invalidate();
            sort(0);
        }
        midnightTimer->start(qMax(1, int(QDateTime::currentDateTime().msecsTo(QDate::currentDate().addDays(1).startOfDay()))));
    });
    midnightTimer->start(qMax(1, int(QDateTime::currentDateTime().msecsTo(QDate::currentDate().addDays(1).startOfDay()))));
}

QVariant ContactListProxyModel::data(const QModelIndex &index, int role) const
{
    if (role == BirthdaySectionRole || role == BirthdayDateRole || role == BirthdayAgeRole) {
        if (!m_birthdaysOnly) {
            return role == BirthdaySectionRole ? QVariant(QString()) : role == BirthdayDateRole ? QVariant(QDate()) : QVariant(0);
        }
        const auto item = QSortFilterProxyModel::data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto birthday = m_birthdays.value(item.id());
        const auto next = nextBirthday(birthday, QDate::currentDate());
        if (!next.isValid()) {
            return role == BirthdaySectionRole ? QVariant(QString()) : role == BirthdayDateRole ? QVariant(QDate()) : QVariant(0);
        }
        if (role == BirthdayDateRole) {
            return next;
        }
        if (role == BirthdayAgeRole) {
            return next.year() - birthday.year();
        }
        return next == QDate::currentDate() ? i18nc("@title:section", "Today") : QLocale().toString(next, u"MMMM yyyy"_s);
    }
    if (role == Qt::DisplayRole) {
        const auto display = QSortFilterProxyModel::data(index, role).toString();
        const auto item = QSortFilterProxyModel::data(index, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        return displayText(display, item);
    }
    return QSortFilterProxyModel::data(index, role);
}

QHash<int, QByteArray> ContactListProxyModel::roleNames() const
{
    auto names = QSortFilterProxyModel::roleNames();
    names.insert(BirthdaySectionRole, "birthdaySection");
    names.insert(BirthdayDateRole, "birthdayDate");
    names.insert(BirthdayAgeRole, "birthdayAge");
    return names;
}

void ContactListProxyModel::setBirthdays(QHash<Akonadi::Item::Id, QDate> birthdays)
{
    if (m_birthdays == birthdays) {
        return;
    }
    m_birthdays = std::move(birthdays);
    if (m_birthdaysOnly) {
        beginFilterChange();
        endFilterChange(Direction::Rows);
        invalidate();
        if (rowCount() > 0) {
            Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, 0), {BirthdaySectionRole, BirthdayDateRole, BirthdayAgeRole});
        }
    }
}

void ContactListProxyModel::setBirthdaysOnly(bool enabled)
{
    if (m_birthdaysOnly == enabled) {
        return;
    }
    m_birthdaysOnly = enabled;
    beginFilterChange();
    endFilterChange(Direction::Rows);
    invalidate();
}

QDate ContactListProxyModel::nextBirthday(const QDate &birthday, const QDate &today)
{
    if (!birthday.isValid() || !today.isValid()) {
        return {};
    }
    auto next = QDate(today.year(), birthday.month(), birthday.day());
    if (!next.isValid()) {
        next = birthday.addYears(today.year() - birthday.year());
    }
    if (next < today) {
        next = QDate(today.year() + 1, birthday.month(), birthday.day());
        if (!next.isValid()) {
            next = birthday.addYears(today.year() + 1 - birthday.year());
        }
    }
    return next;
}

bool ContactListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_birthdaysOnly) {
        const auto sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
        const auto item = sourceIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (!m_birthdays.value(item.id()).isValid()) {
            return false;
        }
    }

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
    const auto emails = addressee.emailList();
    for (const auto &email : emails) {
        searchableFields.append(email.mail());
    }
    const auto phoneNumbers = addressee.phoneNumbers();
    for (const auto &phoneNumber : phoneNumbers) {
        searchableFields.append(phoneNumber.number());
    }

    return std::any_of(searchableFields.cbegin(), searchableFields.cend(), [&expression](const QString &field) {
        return expression.match(field).hasMatch();
    });
}

bool ContactListProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (m_birthdaysOnly) {
        const auto leftItem = left.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto rightItem = right.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        const auto today = QDate::currentDate();
        const auto leftDate = nextBirthday(m_birthdays.value(leftItem.id()), today);
        const auto rightDate = nextBirthday(m_birthdays.value(rightItem.id()), today);
        if (leftDate != rightDate) {
            return leftDate < rightDate;
        }
    }
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
