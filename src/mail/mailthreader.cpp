// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailthreader.h"

#include <Akonadi/MessageStatus>
#include <KMime/Headers>
#include <KMime/Message>
#include <MessageCore/StringUtil>

using namespace Qt::Literals::StringLiterals;

MailThreader::MailThreader(QObject *parent)
    : QObject(parent)
{
}

void MailThreader::buildThreads(const QList<Akonadi::Item> &items)
{
    m_items.clear();
    m_messageIdLookup.clear();
    m_nodes.clear();
    m_rootIds.clear();

    if (items.isEmpty()) {
        return;
    }

    for (const auto &item : items) {
        if (!item.hasPayload<std::shared_ptr<KMime::Message>>()) {
            continue;
        }
        const auto mail = item.payload<std::shared_ptr<KMime::Message>>();

        ThreadItem ti;
        ti.itemId = item.id();
        ti.date = mail->date() ? mail->date()->dateTime() : QDateTime();

        const auto mid = mail->messageID();
        if (mid && !mid->isEmpty()) {
            ti.messageId = mid->identifier();
        }

        const auto irt = mail->inReplyTo();
        if (irt && !irt->isEmpty()) {
            const auto ids = irt->identifiers();
            if (!ids.isEmpty()) {
                ti.inReplyTo = ids.constFirst();
            }
            for (const auto &ref : ids) {
                if (!ref.isEmpty()) {
                    ti.references.append(ref);
                }
            }
        }

        const auto refs = mail->references();
        if (refs && !refs->isEmpty()) {
            for (const auto &r : refs->identifiers()) {
                if (!r.isEmpty()) {
                    ti.references.append(r);
                }
            }
        }

        const QString subject = mail->subject() ? mail->subject()->asUnicodeString() : QString();
        ti.strippedSubject = MessageCore::StringUtil::stripOffPrefixes(subject);
        ti.isReply = ti.strippedSubject != subject;

        Akonadi::MessageStatus stat;
        stat.setStatusFromFlags(item.flags());
        ti.isRead = stat.isRead();

        m_items.append(ti);
    }

    buildLookups();
    matchInReplyTo();
    matchReferences();
    matchSubjects();
    computeThreadInfo();
}

void MailThreader::buildLookups()
{
    for (const auto &ti : std::as_const(m_items)) {
        if (!ti.messageId.isEmpty()) {
            m_messageIdLookup[ti.messageId] = ti.itemId;
        }

        ThreadNode node;
        node.itemId = ti.itemId;
        node.isRead = ti.isRead;
        node.latestReplyDate = ti.date;
        m_nodes[ti.itemId] = node;
    }
}

void MailThreader::matchInReplyTo()
{
    for (auto &ti : m_items) {
        if (ti.inReplyTo.isEmpty() || m_nodes[ti.itemId].parentId != -1) {
            continue;
        }
        const auto it = m_messageIdLookup.constFind(ti.inReplyTo);
        if (it != m_messageIdLookup.constEnd() && it.value() != ti.itemId && !wouldCreateLoop(ti.itemId, it.value())) {
            assignParent(ti.itemId, it.value());
        }
    }
}

void MailThreader::matchReferences()
{
    for (auto &ti : m_items) {
        if (m_nodes[ti.itemId].parentId != -1) {
            continue;
        }
        if (ti.references.isEmpty()) {
            continue;
        }
        for (int i = ti.references.size() - 1; i >= 0; --i) {
            const auto it = m_messageIdLookup.constFind(ti.references.at(i));
            if (it != m_messageIdLookup.constEnd() && it.value() != ti.itemId && !wouldCreateLoop(ti.itemId, it.value())) {
                assignParent(ti.itemId, it.value());
                break;
            }
        }
    }
}

void MailThreader::matchSubjects()
{
    // Group unmatched items by stripped subject
    QHash<QString, QList<int>> subjectGroups;
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_nodes[m_items[i].itemId].parentId == -1 && !m_items[i].strippedSubject.isEmpty()) {
            subjectGroups[m_items[i].strippedSubject].append(i);
        }
    }

    for (auto it = subjectGroups.begin(); it != subjectGroups.end(); ++it) {
        auto &indices = it.value();
        if (indices.size() < 2) {
            continue;
        }

        // Sort by date ascending
        std::sort(indices.begin(), indices.end(), [this](int a, int b) {
            return m_items[a].date < m_items[b].date;
        });

        for (int i = 1; i < indices.size(); ++i) {
            const auto childIdx = indices[i];
            auto &child = m_items[childIdx];

            // Only match replies to older messages
            if (!child.isReply) {
                continue;
            }

            Akonadi::Item::Id parentId = -1;
            for (int j = i - 1; j >= 0; --j) {
                const auto candidateIdx = indices[j];
                const auto &candidate = m_items[candidateIdx];

                // Must be older by at least 120 seconds
                const qint64 secsDiff = candidate.date.secsTo(child.date);
                if (secsDiff < 120) {
                    continue;
                }
                // Must be within 6 weeks
                if (secsDiff > 60 * 60 * 24 * 42) {
                    continue;
                }
                // Skip if would create loop
                if (wouldCreateLoop(child.itemId, candidate.itemId)) {
                    continue;
                }
                parentId = candidate.itemId;
                break;
            }

            if (parentId != -1) {
                assignParent(child.itemId, parentId);
            }
        }
    }
}

void MailThreader::assignParent(Akonadi::Item::Id childId, Akonadi::Item::Id parentId)
{
    auto &childNode = m_nodes[childId];
    auto &parentNode = m_nodes[parentId];
    childNode.parentId = parentId;
    parentNode.childIds.append(childId);
}

bool MailThreader::wouldCreateLoop(Akonadi::Item::Id childId, Akonadi::Item::Id candidateParentId) const
{
    if (childId == candidateParentId) {
        return true;
    }
    Akonadi::Item::Id current = candidateParentId;
    while (true) {
        const auto it = m_nodes.constFind(current);
        if (it == m_nodes.constEnd()) {
            break;
        }
        if (it->parentId == childId) {
            return true;
        }
        if (it->parentId == -1 || it->parentId == current) {
            break;
        }
        current = it->parentId;
    }
    return false;
}

void MailThreader::computeThreadInfo()
{
    m_rootIds.clear();

    // Find roots
    QHash<Akonadi::Item::Id, bool> isRoot;
    for (auto it = m_nodes.begin(); it != m_nodes.end(); ++it) {
        isRoot[it.key()] = true;
    }
    for (auto it = m_nodes.begin(); it != m_nodes.end(); ++it) {
        if (it->parentId != -1) {
            isRoot[it.key()] = false;
        }
    }

    // Compute depth (BFS from roots)
    struct DepthTask {
        Akonadi::Item::Id id;
        int depth;
    };
    QList<DepthTask> queue;
    for (auto it = isRoot.begin(); it != isRoot.end(); ++it) {
        if (it.value()) {
            queue.append({it.key(), 0});
        }
    }
    while (!queue.isEmpty()) {
        const auto task = queue.takeFirst();
        auto &node = m_nodes[task.id];
        node.depth = task.depth;
        for (const auto &childId : std::as_const(node.childIds)) {
            queue.append({childId, task.depth + 1});
        }
    }

    // Compute thread sizes, unread counts, and latest dates (bottom-up from leaves)
    QSet<Akonadi::Item::Id> visited;
    std::function<void(Akonadi::Item::Id)> computeNode = [&](Akonadi::Item::Id id) {
        if (visited.contains(id)) {
            return;
        }
        visited.insert(id);
        auto &node = m_nodes[id];
        for (const auto &childId : std::as_const(node.childIds)) {
            computeNode(childId);
            const auto &childNode = m_nodes[childId];
            node.threadSize += childNode.threadSize;
            node.threadUnread += childNode.threadUnread;
            if (childNode.latestReplyDate > node.latestReplyDate) {
                node.latestReplyDate = childNode.latestReplyDate;
            }
        }
        if (!node.isRead) {
            node.threadUnread++;
        }
    };

    for (auto it = isRoot.begin(); it != isRoot.end(); ++it) {
        if (it.value()) {
            computeNode(it.key());
        }
    }

    // Build ordered root list: sort by latest reply date descending
    QList<QPair<Akonadi::Item::Id, QDateTime>> datedRoots;
    for (auto it = isRoot.begin(); it != isRoot.end(); ++it) {
        if (it.value()) {
            datedRoots.append({it.key(), m_nodes[it.key()].latestReplyDate});
        }
    }
    std::sort(datedRoots.begin(), datedRoots.end(), [](const auto &a, const auto &b) {
        return a.second > b.second;
    });
    for (const auto &pair : std::as_const(datedRoots)) {
        m_rootIds.append(pair.first);
    }
}

bool MailThreader::hasThreading() const
{
    return !m_nodes.isEmpty();
}

QList<Akonadi::Item::Id> MailThreader::rootIds() const
{
    return m_rootIds;
}

const ThreadNode *MailThreader::node(Akonadi::Item::Id id) const
{
    const auto it = m_nodes.constFind(id);
    if (it != m_nodes.constEnd()) {
        return &it.value();
    }
    return nullptr;
}

int MailThreader::threadDepth(Akonadi::Item::Id id) const
{
    const auto *n = node(id);
    return n ? n->depth : 0;
}

int MailThreader::threadSize(Akonadi::Item::Id id) const
{
    const auto *n = node(id);
    return n ? n->threadSize : 1;
}

int MailThreader::threadUnread(Akonadi::Item::Id id) const
{
    const auto *n = node(id);
    return n ? n->threadUnread : 0;
}

bool MailThreader::hasChildren(Akonadi::Item::Id id) const
{
    const auto *n = node(id);
    return n ? !n->childIds.isEmpty() : false;
}

Akonadi::Item::Id MailThreader::threadRootId(Akonadi::Item::Id id) const
{
    if (!m_nodes.contains(id)) {
        return -1;
    }
    Akonadi::Item::Id current = id;
    QSet<Akonadi::Item::Id> visited;
    while (true) {
        if (visited.contains(current)) {
            return current;
        }
        visited.insert(current);
        const auto it = m_nodes.constFind(current);
        if (it == m_nodes.constEnd() || it->parentId == -1) {
            return current;
        }
        current = it->parentId;
    }
}

QDateTime MailThreader::threadRootDate(Akonadi::Item::Id id) const
{
    const auto rootId = threadRootId(id);
    const auto it = m_nodes.constFind(rootId);
    if (it == m_nodes.constEnd()) {
        return {};
    }
    return it->latestReplyDate;
}

#include "moc_mailthreader.cpp"
