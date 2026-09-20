// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kdatetimefactory.h"

KDateTimeFactory::KDateTimeFactory(QObject *parent)
    : QObject(parent)
{
}

Merkuro::KDateTime KDateTimeFactory::now() const
{
    return Merkuro::KDateTime(QDateTime::currentDateTime());
}

Merkuro::KDateTime KDateTimeFactory::fromDateTime(const QDateTime &dateTime) const
{
    return Merkuro::KDateTime(dateTime);
}

Merkuro::KDateTime KDateTimeFactory::fromLocaleTimeString(const QString &value, QLocale::FormatType format) const
{
    const auto time = QLocale().toTime(value, format);
    return time.isValid() ? Merkuro::KDateTime(QDateTime(QDate::currentDate(), time)) : Merkuro::KDateTime();
}

Merkuro::KDateTime KDateTimeFactory::invalid() const
{
    return Merkuro::KDateTime();
}
