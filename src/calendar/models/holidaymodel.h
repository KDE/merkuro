// SPDX-FileCopyrightText: 2025 Shubham Shinde <shubshinde8381@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KHolidays/HolidayRegion>
#include <QDate>
#include <QHash>
#include <QObject>

class HolidayModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString regionCode READ regionCode WRITE setRegionCode NOTIFY regionCodeChanged)

public:
    explicit HolidayModel(QObject *parent = nullptr);

    Q_INVOKABLE void setDateRange(const QDate &start, const QDate &end);
    Q_INVOKABLE QStringList getHolidays(const QDate &date) const;
    Q_INVOKABLE QDate addDaysToDate(const QDate &date, int days) const;
    QString regionCode() const;
    void setRegionCode(const QString &regionCode);

Q_SIGNALS:
    void regionCodeChanged();

private:
    QString m_regionCode;
    QHash<QDate, QStringList> m_holidays;

    void loadSystemRegionCode();
};
