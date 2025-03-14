// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KCalendarCore/Calendar>
#include <QAbstractItemModel>

#include <qqmlintegration.h>

/**
 * This class provides a QAbstractItemModel for an incidences' reminders/alarms.
 * This can be useful for letting users add, modify, or delete incidences on new or pre-existing incidences.
 * It treats the incidence's list of alarms as the single source of truth (and it should be kept this way!)
 *
 * The data for the model comes from m_incidence, which is set in the constructor. This is a pointer to the
 * incidence this model is getting the alarm info from. All alarm pointers are then added to m_alarms, which
 * is a list. Elements in this model are therefore accessed through row numbers, as the list is a one-
 * dimensional data structure.
 */

class RemindersModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidence READ incidence WRITE setIncidence NOTIFY incidenceChanged)
    Q_PROPERTY(KCalendarCore::Alarm::List alarms READ alarms NOTIFY alarmsChanged)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        SummaryRole,
        TimeRole,
        StartOffsetRole,
        EndOffsetRole,
    };
    Q_ENUM(Roles)

    explicit RemindersModel(QObject *parent = nullptr);
    ~RemindersModel() override = default;

    KCalendarCore::Incidence::Ptr incidence() const;
    void setIncidence(KCalendarCore::Incidence::Ptr incidence);
    [[nodiscard]] KCalendarCore::Alarm::List alarms() const;

    QVariant data(const QModelIndex &idx, int role) const override;
    bool setData(const QModelIndex &idx, const QVariant &value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAlarm();
    Q_INVOKABLE void deleteAlarm(const int row);

Q_SIGNALS:
    void incidenceChanged();
    void alarmsChanged();

private:
    KCalendarCore::Incidence::Ptr m_incidence;
    QVariantMap m_dataRoles;
};
