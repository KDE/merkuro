// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "incidenceoccurrencemodel.h"
#include "merkuro_calendar_debug.h"

#include "../filter.h"
#include "../utils.h"
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/EntityTreeModel>
#include <KCalendarCore/OccurrenceIterator>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QMetaEnum>

IncidenceOccurrenceModel::IncidenceOccurrenceModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_coreCalendar(nullptr)
{
    m_resetThrottlingTimer.setSingleShot(true);
    QObject::connect(&m_resetThrottlingTimer, &QTimer::timeout, this, &IncidenceOccurrenceModel::resetFromSource);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, QStringLiteral("Resources Colors"));
    m_colorWatcher = KConfigWatcher::create(config);

    // This is quite slow; would be nice to find a quicker way
    connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &IncidenceOccurrenceModel::resetFromSource);
}

void IncidenceOccurrenceModel::setStart(const QDate &start)
{
    if (start == mStart) {
        return;
    }

    mStart = start;
    Q_EMIT startChanged();

    mEnd = mStart.addDays(mLength);
    scheduleReset();
}

QDate IncidenceOccurrenceModel::start() const
{
    return mStart;
}

void IncidenceOccurrenceModel::setLength(int length)
{
    if (mLength == length) {
        return;
    }
    mLength = length;
    Q_EMIT lengthChanged();

    mEnd = mStart.addDays(mLength);
    scheduleReset();
}

int IncidenceOccurrenceModel::length() const
{
    return mLength;
}

Filter *IncidenceOccurrenceModel::filter() const
{
    return mFilter;
}

void IncidenceOccurrenceModel::setFilter(Filter *filter)
{
    if (mFilter == filter) {
        return;
    }
    if (mFilter) {
        disconnect(mFilter, nullptr, this, nullptr);
    }
    mFilter = filter;
    if (mFilter) {
        connect(mFilter, &Filter::collectionIdChanged, this, &IncidenceOccurrenceModel::scheduleReset);
        connect(mFilter, &Filter::nameChanged, this, &IncidenceOccurrenceModel::scheduleReset);
        connect(mFilter, &Filter::tagsChanged, this, &IncidenceOccurrenceModel::scheduleReset);
    }
    Q_EMIT filterChanged();

    scheduleReset();
}

bool IncidenceOccurrenceModel::loading() const
{
    return m_loading;
}

void IncidenceOccurrenceModel::setLoading(const bool loading)
{
    if (loading == m_loading) {
        return;
    }

    m_loading = loading;
    Q_EMIT loadingChanged();
}

int IncidenceOccurrenceModel::resetThrottleInterval() const
{
    return m_resetThrottleInterval;
}

void IncidenceOccurrenceModel::setResetThrottleInterval(const int resetThrottleInterval)
{
    if (resetThrottleInterval == m_resetThrottleInterval) {
        return;
    }

    m_resetThrottleInterval = resetThrottleInterval;
    Q_EMIT resetThrottleIntervalChanged();
}

void IncidenceOccurrenceModel::scheduleReset()
{
    if (!m_resetThrottlingTimer.isActive()) {
        // Instant update, but then only refresh every interval at most.
        m_resetThrottlingTimer.start(m_resetThrottleInterval);
    }
}

void IncidenceOccurrenceModel::resetFromSource()
{
    if (!m_coreCalendar) {
        qCWarning(MERKURO_CALENDAR_LOG) << "Not resetting IOC from source as no core calendar set.";
        return;
    }

    setLoading(true);

    if (m_resetThrottlingTimer.isActive() || m_coreCalendar->isLoading()) {
        // If calendar is still loading then just schedule a refresh later
        // If refresh timer already active this won't restart it
        scheduleReset();
        return;
    }

    loadColors();

    beginResetModel();

    m_incidences.clear();

    KCalendarCore::OccurrenceIterator occurrenceIterator(*m_coreCalendar, QDateTime(mStart, {0, 0, 0}), QDateTime(mEnd, {12, 59, 59}));

    while (occurrenceIterator.hasNext()) {
        occurrenceIterator.next();
        const auto incidence = occurrenceIterator.incidence();

        if (!incidencePassesFilter(incidence)) {
            continue;
        }

        const auto occurrenceStartEnd = incidenceOccurrenceStartEnd(occurrenceIterator.occurrenceStartDate(), incidence);
        const auto start = occurrenceStartEnd.first;
        const auto end = occurrenceStartEnd.second;

        const Occurrence occurrence{
            start,
            end,
            incidence,
            getColor(incidence),
            getCollectionId(incidence),
            incidence->allDay(),
        };

        m_incidences.append(occurrence);
    }

    endResetModel();

    setLoading(false);
}

int IncidenceOccurrenceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_incidences.size();
}

qint64 IncidenceOccurrenceModel::getCollectionId(const KCalendarCore::Incidence::Ptr &incidence)
{
    auto item = m_coreCalendar->item(incidence);
    if (!item.isValid()) {
        return {};
    }
    auto collection = item.parentCollection();
    if (!collection.isValid()) {
        return {};
    }
    return collection.id();
}

QColor IncidenceOccurrenceModel::getColor(const KCalendarCore::Incidence::Ptr &incidence)
{
    if (!incidence->color().isEmpty()) {
        return incidence->color();
    }

    const auto item = m_coreCalendar->item(incidence);
    if (!item.isValid()) {
        return {};
    }

    const auto collection = item.parentCollection();
    if (!collection.isValid()) {
        return {};
    }

    const auto id = collection.id();

    if (collection.hasAttribute<Akonadi::CollectionColorAttribute>()) {
        const auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>();
        if (colorAttr && colorAttr->color().isValid()) {
            m_colors[id] = colorAttr->color();
            return colorAttr->color();
        }
    }

    if (m_colors.contains(id)) {
        return m_colors[id];
    }

    return {};
}

QVariant IncidenceOccurrenceModel::data(const QModelIndex &idx, int role) const
{
    Q_ASSERT(hasIndex(idx.row(), idx.column()));

    const auto occurrence = m_incidences.at(idx.row());
    const auto incidence = occurrence.incidence;

    switch (role) {
    case Qt::DisplayRole:
    case Qt::EditRole:
    case Summary:
        return incidence->summary();
    case Qt::DecorationRole:
        switch (incidence->type()) {
        case KCalendarCore::IncidenceBase::TypeTodo:
            return QIcon::fromTheme(QStringLiteral("view-pim-tasks"));
        case KCalendarCore::IncidenceBase::TypeEvent:
            return QIcon::fromTheme(QStringLiteral("view-pim-calendar"));
        case KCalendarCore::IncidenceBase::TypeJournal:
            return QIcon::fromTheme(QStringLiteral("view-pim-journal"));
        default:
            Q_UNREACHABLE();
        }
    case Description:
        return incidence->description();
    case Location:
        return incidence->location();
    case StartTime:
        return occurrence.start;
    case EndTime:
        return occurrence.end;
    case Duration: {
        const KCalendarCore::Duration duration(occurrence.start, occurrence.end);
        return QVariant::fromValue(duration);
    }
    case DurationString: {
        const KCalendarCore::Duration duration(occurrence.start, occurrence.end);
        return Utils::formatSpelloutDuration(duration, m_format, occurrence.allDay);
    }
    case Recurs:
        return incidence->recurs();
    case HasReminders:
        return incidence->alarms().length() > 0;
    case Priority:
        return incidence->priority();
    case Color:
        return occurrence.color;
    case CollectionId:
        return occurrence.collectionId;
    case AllDay:
        return occurrence.allDay;
    case TodoCompleted: {
        if (incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = incidence.staticCast<KCalendarCore::Todo>();
        return todo->isCompleted();
    }
    case IsOverdue: {
        if (incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = incidence.staticCast<KCalendarCore::Todo>();
        return todo->isOverdue();
    }
    case IsReadOnly: {
        const auto collection = m_coreCalendar->collection(occurrence.collectionId);
        return collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    }
    case IncidenceId:
        return incidence->uid();
    case IncidenceType:
        return incidence->type();
    case IncidenceTypeStr:
        return incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n(incidence->typeStr().constData());
    case IncidenceTypeIcon:
        return incidence->iconName();
    case IncidencePtr:
        return QVariant::fromValue(incidence);
    case IncidenceOccurrence:
        return QVariant::fromValue(occurrence);
    default:
        return {};
    }
}

void IncidenceOccurrenceModel::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    if (m_coreCalendar == calendar) {
        return;
    }
    m_coreCalendar = calendar;

    connect(m_coreCalendar->model(), &QAbstractItemModel::dataChanged, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::rowsInserted, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::rowsRemoved, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::layoutChanged, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::modelReset, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::rowsMoved, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar.get(), &Akonadi::ETMCalendar::collectionsRemoved, this, &IncidenceOccurrenceModel::scheduleReset);

    Q_EMIT calendarChanged();

    scheduleReset();
}

Akonadi::ETMCalendar::Ptr IncidenceOccurrenceModel::calendar() const
{
    return m_coreCalendar;
}

void IncidenceOccurrenceModel::loadColors()
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, QStringLiteral("Resources Colors"));
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        const auto keyId = key.toLong();
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        m_colors[keyId] = color;
    }
}

std::pair<QDateTime, QDateTime> IncidenceOccurrenceModel::incidenceOccurrenceStartEnd(const QDateTime &ocStart, const KCalendarCore::Incidence::Ptr &incidence)
{
    auto start = ocStart;
    const auto end = incidence->endDateForStart(start);

    if (incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = incidence.staticCast<KCalendarCore::Todo>();

        if (!start.isValid()) { // Todos are very likely not to have a set start date
            start = todo->dtDue();
        }
    }

    return {start, end};
}

bool IncidenceOccurrenceModel::incidencePassesFilter(const KCalendarCore::Incidence::Ptr &incidence)
{
    if (!mFilter || mFilter->tags().empty()) {
        return true;
    }

    const auto tags = mFilter->tags();
    return std::any_of(tags.cbegin(), tags.cend(), [&incidence](const QString &tag) {
        return incidence->categories().contains(tag);
    });
}

#include "moc_incidenceoccurrencemodel.cpp"
