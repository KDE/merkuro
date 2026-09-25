// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@schwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactactivitymodel.h"
#include "merkuro_contact_debug.h"

#include <Akonadi/CalendarUtils>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemSearchJob>
#include <Akonadi/MessageFlags>
#include <Akonadi/MessageParts>
#include <Akonadi/MessageStatus>
#include <Akonadi/SearchQuery>
#include <KCalendarCore/Event>
#include <KIO/CommandLauncherJob>
#include <KJob>
#include <KMime/Message>
#include <QLocale>

#include <algorithm>

using namespace Qt::Literals::StringLiterals;

namespace
{
QDateTime itemDate(const Akonadi::Item &item, ContactActivityModel::Kind kind)
{
    if (kind == ContactActivityModel::Events) {
        const auto incidence = Akonadi::CalendarUtils::incidence(item);
        return incidence ? incidence->dtStart() : QDateTime{};
    }
    if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
        const auto message = item.payload<std::shared_ptr<KMime::Message>>();
        return message->date() ? message->date()->dateTime() : QDateTime{};
    }
    return {};
}
}

ContactActivityModel::ContactActivityModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

QStringList ContactActivityModel::emails() const
{
    return m_emails;
}

void ContactActivityModel::setEmails(const QStringList &emails)
{
    QStringList normalized;
    for (const auto &email : emails) {
        const auto value = email.trimmed().toLower();
        if (!value.isEmpty() && !normalized.contains(value)) {
            normalized.append(value);
        }
    }
    if (normalized == m_emails) {
        return;
    }
    m_emails = normalized;
    Q_EMIT emailsChanged();
    search();
}

ContactActivityModel::Kind ContactActivityModel::kind() const
{
    return m_kind;
}

void ContactActivityModel::setKind(Kind kind)
{
    if (m_kind == kind) {
        return;
    }
    m_kind = kind;
    Q_EMIT kindChanged();
    search();
}

int ContactActivityModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

int ContactActivityModel::count() const
{
    return m_items.size();
}

QVariant ContactActivityModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid)) {
        return {};
    }
    const auto &item = m_items.at(index.row());
    if (role == UnreadRole) {
        if (m_kind != Messages) {
            return false;
        }
        Akonadi::MessageStatus status;
        status.setStatusFromFlags(item.flags());
        return !status.isRead();
    }
    if (role == DateRole) {
        return QLocale().toString(itemDate(item, m_kind), QLocale::ShortFormat);
    }
    if (role == TitleRole) {
        if (m_kind == Events) {
            const auto incidence = Akonadi::CalendarUtils::incidence(item);
            return incidence ? incidence->summary() : QString{};
        }
        if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
            const auto message = item.payload<std::shared_ptr<KMime::Message>>();
            return message->subject() ? message->subject()->asUnicodeString() : QString{};
        }
    }
    if (role == PersonRole || role == EmailRole) {
        if (m_kind == Events) {
            const auto incidence = Akonadi::CalendarUtils::incidence(item);
            if (!incidence) {
                return {};
            }
            const auto organizer = incidence->organizer();
            return role == EmailRole ? organizer.email() : (organizer.name().isEmpty() ? organizer.email() : organizer.name());
        }
        if (item.hasPayload<std::shared_ptr<KMime::Message>>()) {
            const auto message = item.payload<std::shared_ptr<KMime::Message>>();
            if (!message->from()) {
                return {};
            }
            if (role == EmailRole) {
                const auto addresses = message->from()->addresses();
                return addresses.isEmpty() ? QString{} : QString::fromUtf8(addresses.constFirst());
            }
            return message->from()->displayString();
        }
    }
    return {};
}

QHash<int, QByteArray> ContactActivityModel::roleNames() const
{
    return {{TitleRole, "title"_ba}, {DateRole, "date"_ba}, {PersonRole, "person"_ba}, {EmailRole, "email"_ba}, {UnreadRole, "unread"_ba}};
}

void ContactActivityModel::openMessage(int row)
{
    if (m_kind != Messages || row < 0 || row >= m_items.size()) {
        return;
    }
    auto *job = new KIO::CommandLauncherJob(u"merkuro-mail"_s, {u"--show-message"_s, QString::number(m_items.at(row).id())});
    job->setDesktopName(u"org.kde.merkuro.mail"_s);
    connect(job, &KJob::result, job, [job]() {
        if (job->error()) {
            qCWarning(MERKURO_CONTACT_LOG) << "Could not start Merkuro Mail:" << job->errorString();
        }
    });
    job->start();

    auto item = m_items.at(row);
    if (item.hasFlag(Akonadi::MessageFlags::Seen) || m_markingRead.contains(item.id())) {
        return;
    }
    m_markingRead.insert(item.id());
    item.setFlag(Akonadi::MessageFlags::Seen);
    auto *modifyJob = new Akonadi::ItemModifyJob(item, this);
    modifyJob->setIgnorePayload(true);
    modifyJob->disableRevisionCheck();
    connect(modifyJob, &KJob::result, this, [this, itemId = item.id()](KJob *result) {
        m_markingRead.remove(itemId);
        if (result->error()) {
            qCWarning(MERKURO_CONTACT_LOG) << "Could not mark message as read:" << result->errorString();
            return;
        }
        for (int row = 0; row < m_items.size(); ++row) {
            if (m_items.at(row).id() == itemId) {
                m_items[row].setFlag(Akonadi::MessageFlags::Seen);
                Q_EMIT dataChanged(index(row, 0), index(row, 0), {UnreadRole});
                return;
            }
        }
    });
}

void ContactActivityModel::search()
{
    if (m_job) {
        disconnect(m_job, nullptr, this, nullptr);
        m_job->kill();
        m_job = nullptr;
    }
    const bool hadItems = !m_items.isEmpty();
    beginResetModel();
    m_items.clear();
    endResetModel();
    if (hadItems) {
        Q_EMIT countChanged();
    }

    if (m_emails.isEmpty()) {
        return;
    }

    Akonadi::SearchQuery query(Akonadi::SearchTerm::RelOr);
    for (const auto &email : std::as_const(m_emails)) {
        if (m_kind == Messages) {
            query.addTerm(Akonadi::EmailSearchTerm(Akonadi::EmailSearchTerm::HeaderFrom, email));
            query.addTerm(Akonadi::EmailSearchTerm(Akonadi::EmailSearchTerm::HeaderTo, email));
            query.addTerm(Akonadi::EmailSearchTerm(Akonadi::EmailSearchTerm::HeaderCC, email));
        } else {
            query.addTerm(Akonadi::IncidenceSearchTerm(Akonadi::IncidenceSearchTerm::Organizer, email));
            for (int status = KCalendarCore::Attendee::NeedsAction; status <= KCalendarCore::Attendee::None; ++status) {
                const QString attendeeStatus = email + QString::number(status);
                query.addTerm(Akonadi::IncidenceSearchTerm(Akonadi::IncidenceSearchTerm::PartStatus, attendeeStatus));
            }
        }
    }

    auto *job = new Akonadi::ItemSearchJob(query, this);
    m_job = job;
    job->setMimeTypes(m_kind == Events ? QStringList{KCalendarCore::Event::eventMimeType()} : QStringList{u"message/rfc822"_s});
    if (m_kind == Messages) {
        job->fetchScope().fetchPayloadPart(Akonadi::MessagePart::Envelope);
    } else {
        job->fetchScope().fetchFullPayload(true);
    }
    connect(job, &KJob::result, this, [this, job]() {
        if (job != m_job) {
            return;
        }
        m_job = nullptr;
        if (job->error()) {
            qCWarning(MERKURO_CONTACT_LOG) << "Contact activity search failed:" << job->errorString();
            return;
        }
        auto items = job->items();
        updateItems(std::move(items));
    });
}

void ContactActivityModel::updateItems(Akonadi::Item::List items)
{
    const auto previousCount = m_items.size();
    if (m_kind == Events) {
        const auto now = QDateTime::currentDateTime();
        items.removeIf([now](const Akonadi::Item &item) {
            const auto date = itemDate(item, Events);
            return !date.isValid() || date > now;
        });
    }
    std::sort(items.begin(), items.end(), [this](const Akonadi::Item &left, const Akonadi::Item &right) {
        return itemDate(left, m_kind) > itemDate(right, m_kind);
    });
    if (items.size() > 5) {
        items.resize(5);
    }
    beginResetModel();
    m_items = std::move(items);
    endResetModel();
    if (previousCount != m_items.size()) {
        Q_EMIT countChanged();
    }
}

#include "moc_contactactivitymodel.cpp"
