// SPDX-FileCopyrightText: 2026 Yuki Joou <yukijoou@kemonomimi.gay>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "imppservicelistmodel.h"

#include <QIcon>

#include <KContacts/Impp>

using namespace Qt::Literals::StringLiterals;

ImppServiceListModel::ImppServiceListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ImppServiceListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return KContacts::Impp::serviceTypes().length();
}

QVariant ImppServiceListModel::data(const QModelIndex &idx, int role) const
{
    const auto &services = KContacts::Impp::serviceTypes();
    const auto &serviceType = services[idx.row()];
    switch (role) {
    case Qt::DisplayRole:
        return KContacts::Impp::serviceLabel(serviceType);
    case Qt::DecorationRole:
        return QIcon(KContacts::Impp::serviceIcon(serviceType));
    case ServiceTypeRole:
        return serviceType;
    }

    return {};
}

QHash<int, QByteArray> ImppServiceListModel::roleNames() const
{
    return {
        {Qt::DisplayRole, "display"_ba},
        {ServiceTypeRole, "serviceType"_ba},
    };
}

#include "moc_imppservicelistmodel.cpp"
