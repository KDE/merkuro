// SPDX-FileCopyrightText: 2024 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Akonadi/Item>
#include <QDateTime>
#include <QHash>
#include <QList>
#include <QObject>
#include <QSet>

struct ThreadNode {
    Akonadi::Item::Id itemId;
    Akonadi::Item::Id parentId = -1;
    QList<Akonadi::Item::Id> childIds;
    int depth = 0;
    int threadSize = 1;
    int threadUnread = 0;
    QDateTime latestReplyDate;
    bool isRead = false;
};

class MailThreader : public QObject
{
    Q_OBJECT

public:
    explicit MailThreader(QObject *parent = nullptr);

    void buildThreads(const QList<Akonadi::Item> &items);

    [[nodiscard]] bool hasThreading() const;
    [[nodiscard]] QList<Akonadi::Item::Id> rootIds() const;
    [[nodiscard]] const ThreadNode *node(Akonadi::Item::Id id) const;
    [[nodiscard]] int threadDepth(Akonadi::Item::Id id) const;
    [[nodiscard]] int threadSize(Akonadi::Item::Id id) const;
    [[nodiscard]] int threadUnread(Akonadi::Item::Id id) const;
    [[nodiscard]] bool hasChildren(Akonadi::Item::Id id) const;
    [[nodiscard]] Akonadi::Item::Id threadRootId(Akonadi::Item::Id id) const;
    [[nodiscard]] QDateTime threadRootDate(Akonadi::Item::Id id) const;

private:
    struct ThreadItem {
        Akonadi::Item::Id itemId;
        QByteArray messageId;
        QByteArray inReplyTo;
        QList<QByteArray> references;
        QString strippedSubject;
        QDateTime date;
        bool isRead = false;
        bool isReply = false; // has Re:/Fwd: prefix
    };

    void buildLookups();
    void matchInReplyTo();
    void matchReferences();
    void matchSubjects();
    void computeThreadInfo();

    void assignParent(Akonadi::Item::Id childId, Akonadi::Item::Id parentId);
    [[nodiscard]] bool wouldCreateLoop(Akonadi::Item::Id childId, Akonadi::Item::Id candidateParentId) const;

    QList<ThreadItem> m_items;
    QHash<QByteArray, Akonadi::Item::Id> m_messageIdLookup;
    QHash<Akonadi::Item::Id, ThreadNode> m_nodes;
    QList<Akonadi::Item::Id> m_rootIds;
};
