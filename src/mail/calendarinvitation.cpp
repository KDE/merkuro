// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarinvitation.h"

#include <KCalendarCore/ICalFormat>
#include <KCalendarCore/MemoryCalendar>
#include <KFormat>
#include <QLocale>
#include <QTextDocumentFragment>
#include <QTimeZone>
#include <QUrlQuery>

using namespace Qt::StringLiterals;

namespace
{
QString plainText(const QString &text, bool rich)
{
    return rich ? QTextDocumentFragment::fromHtml(text).toPlainText() : text;
}

QString formattedDateTime(const QDateTime &dateTime, bool allDay)
{
    if (!dateTime.isValid()) {
        return {};
    }
    const auto local = allDay ? dateTime : dateTime.toLocalTime();
    const auto locale = QLocale::system();
    const auto date = locale.toString(local.date(), QLocale::LongFormat);
    return allDay ? date : date + u" · "_s + KFormat(locale).formatTime(local, QLocale::ShortFormat, KFormat::AddTimezoneAbbreviationIfNeeded);
}
} // namespace

CalendarInvitation::CalendarInvitation(QObject *parent)
    : QObject(parent)
{
}

QString CalendarInvitation::content() const
{
    return m_content;
}

void CalendarInvitation::setContent(const QString &content)
{
    if (m_content == content) {
        return;
    }
    m_content = content;
    if (content.isEmpty()) {
        m_event.clear();
        m_canceled = false;
        Q_EMIT contentChanged();
        return;
    }
    KCalendarCore::ICalFormat format;
    const auto calendar = KCalendarCore::MemoryCalendar::Ptr::create(QTimeZone::systemTimeZone());
    const auto schedule = format.parseScheduleMessage(calendar, content.toUtf8());
    m_event = schedule ? schedule->event().dynamicCast<KCalendarCore::Event>() : format.fromString(content).dynamicCast<KCalendarCore::Event>();
    m_canceled = schedule && schedule->method() == KCalendarCore::iTIPCancel;
    Q_EMIT contentChanged();
}

bool CalendarInvitation::isValid() const
{
    return !m_event.isNull();
}

bool CalendarInvitation::allDay() const
{
    return m_event && m_event->allDay();
}

bool CalendarInvitation::canceled() const
{
    return m_event && (m_canceled || m_event->status() == KCalendarCore::Incidence::StatusCanceled);
}

QString CalendarInvitation::summary() const
{
    return m_event ? plainText(m_event->summary(), m_event->summaryIsRich()) : QString();
}

QString CalendarInvitation::organizer() const
{
    return m_event ? m_event->organizer().fullName() : QString();
}

QString CalendarInvitation::location() const
{
    return m_event ? plainText(m_event->location(), m_event->locationIsRich()) : QString();
}

QUrl CalendarInvitation::locationUrl() const
{
    if (!m_event) {
        return {};
    }
    const QUrl locationLink(location().trimmed());
    if (locationLink.scheme().compare("http"_L1, Qt::CaseInsensitive) == 0 || locationLink.scheme().compare("https"_L1, Qt::CaseInsensitive) == 0) {
        return locationLink;
    }
    if (m_event->hasGeo()) {
        return QUrl(u"geo:%1,%2"_s.arg(m_event->geoLatitude(), 0, 'f', 6).arg(m_event->geoLongitude(), 0, 'f', 6));
    }
    if (location().isEmpty()) {
        return {};
    }
    QUrl url(u"geo:0,0"_s);
    QUrlQuery query;
    query.addQueryItem(u"q"_s, location());
    url.setQuery(query);
    return url;
}

QString CalendarInvitation::description() const
{
    return m_event ? plainText(m_event->description(), m_event->descriptionIsRich()) : QString();
}

QString CalendarInvitation::dateTimeRange() const
{
    if (!m_event || !m_event->dtStart().isValid()) {
        return {};
    }
    const auto start = allDay() ? m_event->dtStart() : m_event->dtStart().toLocalTime();
    const auto end = allDay() ? m_event->dtEnd() : m_event->dtEnd().toLocalTime();
    const auto locale = QLocale::system();
    const auto date = locale.toString(start.date(), QLocale::ShortFormat);
    if (allDay()) {
        return m_event->hasEndDate() && end.isValid() && end.date() != start.date() ? date + u" – "_s + locale.toString(end.date(), QLocale::ShortFormat)
                                                                                    : date;
    }
    const auto startTime = KFormat(locale).formatTime(start, QLocale::ShortFormat, KFormat::AddTimezoneAbbreviationIfNeeded);
    if (!m_event->hasEndDate() || !end.isValid() || start == end) {
        return date + u" · "_s + startTime;
    }
    const auto endTime = KFormat(locale).formatTime(end, QLocale::ShortFormat, KFormat::AddTimezoneAbbreviationIfNeeded);
    const auto endText = start.date() == end.date() ? endTime : locale.toString(end.date(), QLocale::ShortFormat) + u" · "_s + endTime;
    return date + u" · "_s + startTime + u" – "_s + endText;
}

QString CalendarInvitation::startTime() const
{
    return m_event ? formattedDateTime(m_event->dtStart(), allDay()) : QString();
}

QString CalendarInvitation::endTime() const
{
    if (!m_event || !m_event->hasEndDate() || (allDay() && m_event->dtStart().date() == m_event->dtEnd().date())) {
        return {};
    }
    // CalendarCore already converts the exclusive iCalendar end date to an
    // inclusive date for all-day events.
    return formattedDateTime(m_event->dtEnd(), allDay());
}

QStringList CalendarInvitation::attendees() const
{
    QStringList names;
    if (m_event) {
        const auto attendees = m_event->attendees();
        names.reserve(attendees.size());
        for (const auto &attendee : attendees) {
            names.push_back(attendee.fullName());
        }
    }
    return names;
}

#include "moc_calendarinvitation.cpp"
