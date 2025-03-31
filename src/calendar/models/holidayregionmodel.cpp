// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "holidayregionmodel.h"

#include <KHolidays/HolidayRegion>
#include <KLocalizedString>
#include <QLocale>

HolidayRegionModel::HolidayRegionModel(QObject *parent)
    : QAbstractListModel(parent)
{
    const auto regions = KHolidays::HolidayRegion::regionCodes();
    regionsMap.reserve(regions.size());
    for (const QString &regionCode : regions) {
        const QString name = KHolidays::HolidayRegion::name(regionCode);
        const QLocale locale(KHolidays::HolidayRegion::languageCode(regionCode));
        const QString languageName = QLocale::languageToString(locale.language());
        QString label;
        if (languageName.isEmpty()) {
            label = name;
        } else {
            label = i18nc("@item:inlistbox Holiday region, region language", "%1 (%2)", name, languageName);
        }
        regionsMap.emplace_back(label, regionCode);
    }
    std::sort(regionsMap.begin(), regionsMap.end(), [](const auto &lhs, const auto &rhs) {
        return lhs.first < rhs.first;
    });

    regionsMap.insert(regionsMap.begin(), {i18nc("@item:inlistbox", "Default from locale"), QString{}});
}

QString HolidayRegionModel::regionLanguage(const QString &regionCode)
{
    for (const auto &region : regionsMap) {
        if (region.second == regionCode) {
            return region.first;
        }
    }
    return {};
}

int HolidayRegionModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return regionsMap.size();
}

QVariant HolidayRegionModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto &region = regionsMap.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
        return region.first;
    case RegionCodeRole:
        return region.second;
    default:
        return {};
    }
}

QHash<int, QByteArray> HolidayRegionModel::roleNames() const
{
    return {
        {Qt::DisplayRole, "displayName"},
        {RegionCodeRole, "regionCode"},
    };
}

#include "moc_holidayregionmodel.cpp"
