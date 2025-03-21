// SPDX-FileCopyrightText: 2025 Shubham Shinde <shubshinde8381@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "holidaymodel.h"
#include <QLocale>

using namespace Qt::StringLiterals;

HolidayModel::HolidayModel(QObject *parent)
    : QObject(parent)
{
}

QStringList HolidayModel::holidayRegions() const
{
    return m_holidayRegions;
}

void HolidayModel::setHolidayRegions(const QStringList &holidayRegions)
{
    if (holidayRegions.isEmpty()) {
        const QLocale locale = QLocale::system();
        const QString country = locale.name().split(u'_').last().toUpper();
        const QString language = locale.name().split(u'_').constFirst().toLower();

        QString region = KHolidays::HolidayRegion::defaultRegionCode(country, language);
        if (KHolidays::HolidayRegion::isValid(region)) {
            m_holidayRegions = {region};
        }
        return;
    }
    if (m_holidayRegions == holidayRegions) {
        return;
    }
    m_holidayRegions = holidayRegions;
    Q_EMIT holidayRegionsChanged();

    // reset everything
    m_fetchedIntervals.clear();
    m_holidays.clear();
    auto start = m_start;
    m_start = {};

    loadDateRange(start, m_days);
}

void HolidayModel::loadDateRange(const QDate &start, int days)
{
    if (days == 0) {
        return;
    }

    const auto it = std::ranges::find(m_fetchedIntervals, std::pair<QDate, int>(start, days));
    if (it != m_fetchedIntervals.end()) {
        // we already fetched this interval
        return;
    }

    const QDate end = start.addDays(days);

    for (const auto &regionCode : std::as_const(m_holidayRegions)) {
        KHolidays::HolidayRegion region(regionCode);
        const auto holidays = region.rawHolidays(start, end);
        for (const auto &holiday : holidays) {
            if (holiday.dayType() != KHolidays::Holiday::NonWorkday) {
                continue;
            }

            const QDate date = holiday.observedStartDate();
            QStringList list = m_holidays[date.toString(u"yyyy-MM-dd"_s)].toStringList();
            if (!list.contains(holiday.name())) {
                list.append(holiday.name());
            }
            m_holidays[date.toString(u"yyyy-MM-dd"_s)] = list;
        }
    }
    Q_EMIT holidaysChanged();
}

QVariantMap HolidayModel::holidays() const
{
    return m_holidays;
}

#include "moc_holidaymodel.cpp"
