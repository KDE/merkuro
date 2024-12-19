// SPDX-FileCopyrightText: 2024 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "abstractmailmodel.h"

#include <Akonadi/Item>
#include <Akonadi/MessageStatus>
#include <KFormat>
#include <KLocalizedString>
#include <KMime/Message>

QVariant AbstractMailModel::dataFromItem(const Akonadi::Item &item, int role) const
{
    if (!item.hasPayload<KMime::Message::Ptr>()) {
        return {};
    }
    const KMime::Message::Ptr mail = item.payload<KMime::Message::Ptr>();

    // Static for speed reasons
    static const QString noSubject = i18nc("displayed as subject when the subject of a mail is empty", "No Subject");
    static const QString unknown(i18nc("displayed when a mail has unknown sender, receiver or date", "Unknown"));

    QString subject = mail->subject()->asUnicodeString();
    if (subject.isEmpty()) {
        subject = QLatin1Char('(') + noSubject + QLatin1Char(')');
    }

    Akonadi::MessageStatus stat;
    stat.setStatusFromFlags(item.flags());

    // NOTE: remember to update AkonadiBrowserSortModel::lessThan if you insert/move columns
    switch (role) {
    case TitleRole:
        if (mail->subject()) {
            return mail->subject()->asUnicodeString();
        } else {
            return noSubject;
        }
    case FromRole:
        if (mail->from()) {
            return mail->from()->asUnicodeString();
        } else {
            return QString();
        }
    case SenderRole:
        if (mail->sender()) {
            return mail->sender()->asUnicodeString();
        } else {
            return QString();
        }
    case ToRole:
        if (mail->to()) {
            return mail->to()->asUnicodeString();
        } else {
            return unknown;
        }
    case DateRole:
        if (mail->date()) {
            KFormat format;
            return format.formatRelativeDate(mail->date()->dateTime().date(), QLocale::LongFormat);
        } else {
            return QString();
        }
    case DateTimeRole:
        if (mail->date()) {
            return mail->date()->dateTime();
        } else {
            return QString();
        }
    case StatusRole:
        return QVariant::fromValue(stat);
    case ItemRole:
        return QVariant::fromValue(item);
    }

    return {};
}

QHash<int, QByteArray> AbstractMailModel::roleNames() const
{
    return {
        {TitleRole, QByteArrayLiteral("title")},
        {DateRole, QByteArrayLiteral("date")},
        {DateTimeRole, QByteArrayLiteral("datetime")},
        {SenderRole, QByteArrayLiteral("sender")},
        {FromRole, QByteArrayLiteral("from")},
        {ToRole, QByteArrayLiteral("to")},
        {StatusRole, QByteArrayLiteral("status")},
        {FavoriteRole, QByteArrayLiteral("favorite")},
        {TextColorRole, QByteArrayLiteral("textColor")},
        {BackgroundColorRole, QByteArrayLiteral("backgroudColor")},
        {ItemRole, QByteArrayLiteral("item")},
    };
}
