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
    Q_PROPERTY(QStringList holidayRegions READ holidayRegions WRITE setHolidayRegions NOTIFY holidayRegionsChanged)
    Q_PROPERTY(QVariantMap holidays READ holidays NOTIFY holidaysChanged)

public:
    explicit HolidayModel(QObject *parent = nullptr);

    Q_INVOKABLE void loadDateRange(const QDate &start, int days);

    [[nodiscard]] QStringList holidayRegions() const;
    void setHolidayRegions(const QStringList &holidayRegions);

    [[nodiscard]] QVariantMap holidays() const;

Q_SIGNALS:
    void holidayRegionsChanged();
    void holidaysChanged();

private:
    QDate m_start;
    int m_days = 0;
    QStringList m_holidayRegions;
    QVariantMap m_holidays;
    std::vector<std::pair<QDate, int>> m_fetchedIntervals;
};
