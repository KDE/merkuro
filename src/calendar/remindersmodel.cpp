// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "remindersmodel.h"
#include "merkuro_calendar_debug.h"
#include <QMetaEnum>
using namespace Qt::Literals::StringLiterals;
RemindersModel::RemindersModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

KCalendarCore::Incidence::Ptr RemindersModel::incidence() const
{
    return m_incidence;
}

void RemindersModel::setIncidence(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;
    Q_EMIT incidenceChanged();
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

KCalendarCore::Alarm::List RemindersModel::alarms() const
{
    if (!m_incidence) {
        return {};
    }
    return m_incidence->alarms();
}

QVariant RemindersModel::data(const QModelIndex &idx, int role) const
{
    Q_ASSERT(m_incidence);
    Q_ASSERT(checkIndex(idx, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    auto alarm = m_incidence->alarms()[idx.row()];
    switch (role) {
    case TypeRole:
        return alarm->type();
    case TimeRole:
        return alarm->time();
    case SummaryRole:
        return alarm->text();
    case StartOffsetRole:
        return alarm->startOffset().asSeconds();
    case EndOffsetRole:
        return alarm->endOffset().asSeconds();
    default:
        qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

bool RemindersModel::setData(const QModelIndex &idx, const QVariant &value, int role)
{
    Q_ASSERT(m_incidence);
    Q_ASSERT(checkIndex(idx, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    if (!idx.isValid()) {
        return false;
    }

    switch (role) {
    case TypeRole: {
        auto type = static_cast<KCalendarCore::Alarm::Type>(value.toInt());
        m_incidence->alarms()[idx.row()]->setType(type);
        break;
    }
    case TimeRole: {
        QDateTime time = value.toDateTime();
        m_incidence->alarms()[idx.row()]->setTime(time);
        break;
    }
    case StartOffsetRole: {
        // offset can be set in seconds or days, if we want it to be before the incidence,
        // it has to be set to a negative value.
        KCalendarCore::Duration offset(value.toInt());
        m_incidence->alarms()[idx.row()]->setStartOffset(offset);
        break;
    }
    case EndOffsetRole: {
        KCalendarCore::Duration offset(value.toInt());
        m_incidence->alarms()[idx.row()]->setEndOffset(offset);
        break;
    }
    default:
        qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return false;
    }
    Q_EMIT dataChanged(idx, idx);
    return true;
}

QHash<int, QByteArray> RemindersModel::roleNames() const
{
    return {
        {TypeRole, "type"_ba},
        {TimeRole, "time"_ba},
        {StartOffsetRole, "startOffset"_ba},
        {EndOffsetRole, "endOffset"_ba},
    };
}

int RemindersModel::rowCount(const QModelIndex &) const
{
    if (!m_incidence) {
        return 0;
    }
    return m_incidence->alarms().size();
}

void RemindersModel::addAlarm()
{
    Q_ASSERT(m_incidence);

    KCalendarCore::Alarm::Ptr alarm(new KCalendarCore::Alarm(m_incidence.get()));
    alarm->setEnabled(true);
    alarm->setType(KCalendarCore::Alarm::Display);
    alarm->setText(m_incidence->summary());
    alarm->setStartOffset(0);

    qCDebug(MERKURO_CALENDAR_LOG) << alarm->parentUid();

    m_incidence->addAlarm(alarm);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

void RemindersModel::deleteAlarm(const int row)
{
    Q_ASSERT(m_incidence);

    if (!hasIndex(row, 0)) {
        return;
    }

    m_incidence->removeAlarm(m_incidence->alarms()[row]);
    Q_EMIT alarmsChanged();
    Q_EMIT layoutChanged();
}

#include "moc_remindersmodel.cpp"
