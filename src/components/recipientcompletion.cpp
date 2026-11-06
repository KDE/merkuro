// SPDX-FileCopyrightText: 2026 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "recipientcompletion.h"

#include <Akonadi/ContactSearchJob>
#include <QSet>

RecipientCompletion::RecipientCompletion(QObject *parent)
    : QObject(parent)
{
    m_searchTimer.setSingleShot(true);
    m_searchTimer.setInterval(300);
    connect(&m_searchTimer, &QTimer::timeout, this, [this] {
        const auto revision = m_revision;
        auto job = new Akonadi::ContactSearchJob(this);
        job->setLimit(5);
        job->setQuery(Akonadi::ContactSearchJob::NameOrEmail, m_searchText, Akonadi::ContactSearchJob::ContainsMatch);
        connect(job, &KJob::result, this, [this, job, revision] {
            if (job->error() || revision != m_revision) {
                return;
            }
            QStringList suggestions;
            QSet<QString> seen;
            const auto contacts = job->contacts();
            for (const auto &contact : contacts) {
                const bool hasName = !contact.formattedName().trimmed().isEmpty() || !contact.assembledName().isEmpty();
                const bool nameMatches = hasName && contact.realName().contains(m_searchText, Qt::CaseInsensitive);
                const auto emails = contact.emails();
                for (const auto &email : emails) {
                    const auto address = email.trimmed();
                    if (address.isEmpty() || (!nameMatches && !address.contains(m_searchText, Qt::CaseInsensitive)) || seen.contains(address.toCaseFolded())) {
                        continue;
                    }
                    seen.insert(address.toCaseFolded());
                    suggestions.append(hasName ? contact.fullEmail(address) : address);
                }
            }
            suggestions.sort(Qt::CaseInsensitive);
            m_suggestions = suggestions.mid(0, 5);
            Q_EMIT suggestionsChanged();
        });
    });
}

QString RecipientCompletion::searchText() const
{
    return m_searchText;
}

void RecipientCompletion::setSearchText(const QString &text)
{
    const auto query = text.trimmed();
    if (m_searchText == query) {
        return;
    }
    m_searchText = query;
    ++m_revision;
    m_searchTimer.stop();
    if (!m_suggestions.isEmpty()) {
        m_suggestions.clear();
        Q_EMIT suggestionsChanged();
    }
    Q_EMIT searchTextChanged();
    if (!m_searchText.isEmpty()) {
        m_searchTimer.start();
    }
}

QStringList RecipientCompletion::suggestions() const
{
    return m_suggestions;
}

#include "moc_recipientcompletion.cpp"
