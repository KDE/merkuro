// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <merkurokdatetime.h>

#include <QDateTime>
#include <QLocale>
#include <QObject>
#include <qqmlregistration.h>

/*!
 * \qmltype KDateTimeFactory
 * \inqmlmodule org.kde.merkuro.components
 *
 * \brief Creates DateTime values from QML.
 *
 * DateTime is a value type and cannot be instantiated directly from QML, so
 * this singleton provides the ways QML code needs to obtain one instead of
 * falling back to JavaScript's \c Date.
 */
class KDateTimeFactory : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit KDateTimeFactory(QObject *parent = nullptr);

    /*!
     * \brief Returns the current date and time.
     */
    Q_INVOKABLE Merkuro::KDateTime now() const;

    /*!
     * \brief Returns dateTime wrapped in a DateTime.
     */
    Q_INVOKABLE Merkuro::KDateTime fromDateTime(const QDateTime &dateTime) const;

    /*!
     * \brief Parses a localized time and returns it on today's date.
     */
    Q_INVOKABLE Merkuro::KDateTime fromLocaleTimeString(const QString &value, QLocale::FormatType format) const;

    /*!
     * \brief Returns an invalid DateTime, for example to clear a bound.
     */
    Q_INVOKABLE Merkuro::KDateTime invalid() const;
};
