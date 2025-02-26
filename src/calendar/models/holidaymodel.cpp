// SPDX-FileCopyrightText: 2025 Shubham Shinde <shubshinde8381@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "holidaymodel.h"
#include <KHolidays/HolidayRegion>
#include <QLocale>

HolidayModel::HolidayModel(QObject *parent)
    : QObject(parent)
{
    loadSystemRegionCode();
}

void HolidayModel::loadSystemRegionCode()
{
    const QLocale locale = QLocale::system();
    const QString country = locale.name().split(u'_').last().toUpper();
    const QString language = locale.name().split(u'_').constFirst().toLower();

    QString region = KHolidays::HolidayRegion::defaultRegionCode(country, language);
    if (!KHolidays::HolidayRegion::isValid(region)) {
        region.clear();
    }
    m_regionCode = region;
}

QString HolidayModel::regionCode() const
{
    return m_regionCode;
}

void HolidayModel::setRegionCode(const QString &regionCode)
{
    if (KHolidays::HolidayRegion::isValid(regionCode) && m_regionCode != regionCode) {
        m_regionCode = regionCode;
        m_holidays.clear();
        Q_EMIT regionCodeChanged();
    }
}

void HolidayModel::setDateRange(const QDate &start, const QDate &end)
{
    m_holidays.clear();
    KHolidays::HolidayRegion region(m_regionCode);
    const auto holidays = region.rawHolidays(start, end);
    for (const auto &holiday : holidays) {
        const QDate date = holiday.observedStartDate();
        m_holidays[date].append(holiday.name());
    }
}

QDate HolidayModel::addDaysToDate(const QDate &date, int days) const
{
    return date.addDays(days);
}

QStringList HolidayModel::getHolidays(const QDate &date) const
{
    return m_holidays.value(date);
}

#include "moc_holidaymodel.cpp"
