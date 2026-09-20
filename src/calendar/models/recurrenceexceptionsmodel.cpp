// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "recurrenceexceptionsmodel.h"
#include "merkuro_calendar_debug.h"
#include <QMetaEnum>
using namespace Qt::Literals::StringLiterals;
RecurrenceExceptionsModel::RecurrenceExceptionsModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
{
    for (int i = 0; i < QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().keyCount(); i++) {
        const int value = QMetaEnum::fromType<RecurrenceExceptionsModel::Roles>().value(i);
        const QString key = QLatin1StringView(roleNames().value(value));
        m_dataRoles[key] = value;
    }

    connect(this, &RecurrenceExceptionsModel::incidencePtrChanged, this, &RecurrenceExceptionsModel::updateExceptions);
}

KCalendarCore::Incidence::Ptr RecurrenceExceptionsModel::incidencePtr()
{
    return m_incidence;
}

void RecurrenceExceptionsModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;
    Q_EMIT incidencePtrChanged();
    Q_EMIT exceptionsChanged();
    Q_EMIT layoutChanged();
}

QList<Merkuro::KDateTime> RecurrenceExceptionsModel::exceptions()
{
    return m_exceptions;
}

void RecurrenceExceptionsModel::updateExceptions()
{
    m_exceptions.clear();

    const auto dateTimes = m_incidence->recurrence()->exDateTimes();
    for (const QDateTime &dateTime : dateTimes) {
        m_exceptions.append(Merkuro::KDateTime(dateTime));
    }

    const auto dates = m_incidence->recurrence()->exDates();
    for (const QDate &date : dates) {
        m_exceptions.append(Merkuro::KDateTime(QDateTime(date, QTime(0, 0))));
    }
    Q_EMIT exceptionsChanged();
    Q_EMIT layoutChanged();
}

QVariantMap RecurrenceExceptionsModel::dataroles()
{
    return m_dataRoles;
}

QVariant RecurrenceExceptionsModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    const auto exception = m_exceptions[idx.row()];
    switch (role) {
    case DateRole:
        return QVariant::fromValue(exception);
    default:
        qCWarning(MERKURO_CALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> RecurrenceExceptionsModel::roleNames() const
{
    return {{DateRole, "date"_ba}};
}

int RecurrenceExceptionsModel::rowCount(const QModelIndex &) const
{
    return m_exceptions.size();
}

void RecurrenceExceptionsModel::addExceptionDateTime(const Merkuro::KDateTime &date)
{
    if (!date.isValid()) {
        return;
    }

    const auto dateTime = date.dateTime();

    // I don't know why, but different types take different date formats
    if (m_incidence->recurrence()->allDay()) {
        m_incidence->recurrence()->addExDateTime(dateTime);
    } else {
        m_incidence->recurrence()->addExDate(dateTime.date());
    }

    updateExceptions();
}

void RecurrenceExceptionsModel::deleteExceptionDateTime(const Merkuro::KDateTime &date)
{
    if (!date.isValid()) {
        return;
    }

    const auto dateTime = date.dateTime();

    if (m_incidence->recurrence()->allDay()) {
        auto dateTimes = m_incidence->recurrence()->exDateTimes();
        dateTimes.removeAt(dateTimes.indexOf(dateTime));
        m_incidence->recurrence()->setExDateTimes(dateTimes);
    } else {
        auto dates = m_incidence->recurrence()->exDates();
        const int removeIndex = dates.indexOf(dateTime.date());

        if (removeIndex >= 0) {
            dates.removeAt(dates.indexOf(dateTime.date()));
            m_incidence->recurrence()->setExDates(dates);
            updateExceptions();
            return;
        }

        auto dateTimes = m_incidence->recurrence()->exDateTimes();

        for (int i = 0; i < dateTimes.size(); i++) {
            if (dateTimes[i].date() == dateTime.date()) {
                dateTimes.removeAt(i);
            }
        }
        m_incidence->recurrence()->setExDateTimes(dateTimes);
    }

    updateExceptions();
}

#include "moc_recurrenceexceptionsmodel.cpp"
