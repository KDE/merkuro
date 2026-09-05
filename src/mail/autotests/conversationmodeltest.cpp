// SPDX-FileCopyrightText: 2026 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: BSD-2-Clause

#include "../conversationmodel.h"
#include "../mailpresentationmodel.h"

#include <Akonadi/MessageStatus>
#include <KMime/Message>
#include <QAbstractItemModelTester>
#include <QDateTime>
#include <QSignalSpy>
#include <QTest>

#include <memory>
#include <utility>

namespace
{
class TestConversationModel final : public ConversationModel
{
public:
    explicit TestConversationModel(QObject *parent = nullptr)
        : ConversationModel(parent)
    {
    }

    void setItems(Akonadi::Item::List items)
    {
        m_items = std::move(items);
    }

    [[nodiscard]] Akonadi::Item::List conversationItems() const override
    {
        return m_items;
    }

private:
    Akonadi::Item::List m_items;
};

Akonadi::Item makeItem(const Akonadi::Item::Id id,
                       const QString &subject,
                       const QString &from,
                       const QString &sender,
                       const QString &to,
                       const QDateTime &dateTime,
                       const bool read = false)
{
    auto message = std::make_shared<KMime::Message>();
    message->subject()->fromUnicodeString(subject);
    message->from()->fromUnicodeString(from);
    message->sender()->fromUnicodeString(sender);
    message->to()->fromUnicodeString(to);
    message->date()->setDateTime(dateTime);

    Akonadi::Item item(id);
    item.setMimeType(KMime::Message::mimeType());
    item.setPayload<std::shared_ptr<KMime::Message>>(message);
    if (read) {
        item.setFlags(Akonadi::MessageStatus::statusRead().statusFlags());
    }
    return item;
}
} // namespace

class ConversationModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void emptyModelHasValidContract()
    {
        ConversationModel model;
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);

        QCOMPARE(model.rowCount(), 0);
        QCOMPARE(model.anchorRow(), -1);

        const auto roles = model.roleNames();
        QCOMPARE(roles.value(ConversationModel::ItemRole), QByteArrayLiteral("item"));
        QCOMPARE(roles.value(ConversationModel::ItemIdRole), QByteArrayLiteral("itemId"));
        QCOMPARE(roles.value(ConversationModel::TitleRole), QByteArrayLiteral("title"));
        QCOMPARE(roles.value(ConversationModel::FromRole), QByteArrayLiteral("from"));
        QCOMPARE(roles.value(ConversationModel::SenderRole), QByteArrayLiteral("sender"));
        QCOMPARE(roles.value(ConversationModel::ToRole), QByteArrayLiteral("to"));
        QCOMPARE(roles.value(ConversationModel::DateTimeRole), QByteArrayLiteral("datetime"));
        QCOMPARE(roles.value(ConversationModel::StatusRole), QByteArrayLiteral("status"));
    }

    void invalidIndexesDoNotExposeData()
    {
        ConversationModel model;
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);

        const auto invalidIndex = QModelIndex{};
        QVERIFY(!model.data(invalidIndex, ConversationModel::ItemRole).isValid());
        QVERIFY(!model.data(invalidIndex, ConversationModel::TitleRole).isValid());
        QCOMPARE(model.rowCount(invalidIndex), 0);
    }

    void settingPropertiesEmitsOnlyOnChanges()
    {
        ConversationModel model;
        MailPresentationModel folderModel;
        const auto item = makeItem(42,
                                   QStringLiteral("Subject"),
                                   QStringLiteral("From <from@example.com>"),
                                   QStringLiteral("Sender <sender@example.com>"),
                                   QStringLiteral("To <to@example.com>"),
                                   QDateTime::fromString(QStringLiteral("2026-09-05T12:34:56Z"), Qt::ISODate));

        QSignalSpy folderChanged(&model, &ConversationModel::folderModelChanged);
        QSignalSpy seedChanged(&model, &ConversationModel::seedItemChanged);
        QSignalSpy modelReset(&model, &QAbstractItemModel::modelReset);

        model.setFolderModel(&folderModel);
        QCOMPARE(folderChanged.count(), 1);
        QCOMPARE(modelReset.count(), 1);

        model.setFolderModel(&folderModel);
        QCOMPARE(folderChanged.count(), 1);
        QCOMPARE(modelReset.count(), 1);

        model.setSeedItem(item);
        QCOMPARE(seedChanged.count(), 1);
        QCOMPARE(modelReset.count(), 2);

        model.setSeedItem(item);
        QCOMPARE(seedChanged.count(), 1);
        QCOMPARE(modelReset.count(), 2);
    }

    void populatedConversationExposesItemsAndRoles()
    {
        const auto first = makeItem(1,
                                    QStringLiteral("First"),
                                    QStringLiteral("First <first@example.com>"),
                                    QStringLiteral("First Sender <sender1@example.com>"),
                                    QStringLiteral("Recipient <recipient@example.com>"),
                                    QDateTime::fromString(QStringLiteral("2026-09-03T10:00:00Z"), Qt::ISODate),
                                    true);
        const auto seed = makeItem(2,
                                   QStringLiteral("Seed"),
                                   QStringLiteral("Seed <seed@example.com>"),
                                   QStringLiteral("Seed Sender <sender2@example.com>"),
                                   QStringLiteral("Recipient <recipient@example.com>"),
                                   QDateTime::fromString(QStringLiteral("2026-09-04T11:00:00Z"), Qt::ISODate));
        const auto last = makeItem(3,
                                   QStringLiteral("Last"),
                                   QStringLiteral("Last <last@example.com>"),
                                   QStringLiteral("Last Sender <sender3@example.com>"),
                                   QStringLiteral("Recipient <recipient@example.com>"),
                                   QDateTime::fromString(QStringLiteral("2026-09-05T12:00:00Z"), Qt::ISODate));

        TestConversationModel model;
        model.setItems({first, seed, last});
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);
        QSignalSpy anchorChanged(&model, &ConversationModel::anchorRowChanged);

        model.setSeedItem(seed);

        QCOMPARE(model.rowCount(), 3);
        QCOMPARE(model.anchorRow(), 1);
        QCOMPARE(anchorChanged.count(), 1);

        const auto firstIndex = model.index(0, 0);
        const auto seedIndex = model.index(1, 0);
        const auto lastIndex = model.index(2, 0);
        QCOMPARE(firstIndex.data(ConversationModel::ItemIdRole).toLongLong(), 1);
        QCOMPARE(seedIndex.data(ConversationModel::ItemIdRole).toLongLong(), 2);
        QCOMPARE(lastIndex.data(ConversationModel::ItemIdRole).toLongLong(), 3);

        const auto returnedItem = seedIndex.data(ConversationModel::ItemRole).value<Akonadi::Item>();
        QCOMPARE(returnedItem.id(), seed.id());
        QCOMPARE(seedIndex.data(ConversationModel::TitleRole).toString(), QStringLiteral("Seed"));
        QCOMPARE(seedIndex.data(ConversationModel::FromRole).toString(), QStringLiteral("Seed <seed@example.com>"));
        QCOMPARE(seedIndex.data(ConversationModel::SenderRole).toString(), QStringLiteral("Seed Sender <sender2@example.com>"));
        QCOMPARE(seedIndex.data(ConversationModel::ToRole).toString(), QStringLiteral("Recipient <recipient@example.com>"));
        QCOMPARE(seedIndex.data(ConversationModel::DateTimeRole).toDateTime(), QDateTime::fromString(QStringLiteral("2026-09-04T11:00:00Z"), Qt::ISODate));

        const auto firstStatus = firstIndex.data(ConversationModel::StatusRole).value<Akonadi::MessageStatus>();
        const auto seedStatus = seedIndex.data(ConversationModel::StatusRole).value<Akonadi::MessageStatus>();
        QVERIFY(firstStatus.isRead());
        QVERIFY(!seedStatus.isRead());
    }

    void anchorFollowsSeedMessage()
    {
        const auto first = makeItem(1,
                                    QStringLiteral("First"),
                                    QStringLiteral("first@example.com"),
                                    QStringLiteral("first@example.com"),
                                    QStringLiteral("recipient@example.com"),
                                    QDateTime::currentDateTimeUtc());
        const auto second = makeItem(2,
                                     QStringLiteral("Second"),
                                     QStringLiteral("second@example.com"),
                                     QStringLiteral("second@example.com"),
                                     QStringLiteral("recipient@example.com"),
                                     QDateTime::currentDateTimeUtc());
        const auto third = makeItem(3,
                                    QStringLiteral("Third"),
                                    QStringLiteral("third@example.com"),
                                    QStringLiteral("third@example.com"),
                                    QStringLiteral("recipient@example.com"),
                                    QDateTime::currentDateTimeUtc());

        TestConversationModel model;
        model.setItems({first, second, third});
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);
        QSignalSpy anchorChanged(&model, &ConversationModel::anchorRowChanged);

        model.setSeedItem(first);
        QCOMPARE(model.anchorRow(), 0);

        model.setSeedItem(third);
        QCOMPARE(model.anchorRow(), 2);
        QCOMPARE(anchorChanged.count(), 2);

        model.setSeedItem(third);
        QCOMPARE(anchorChanged.count(), 2);
    }

    void emptySourceProducesEmptyConversation()
    {
        TestConversationModel model;
        model.setItems({});
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);

        model.setSeedItem(makeItem(99,
                                   QStringLiteral("Missing"),
                                   QStringLiteral("from@example.com"),
                                   QStringLiteral("from@example.com"),
                                   QStringLiteral("to@example.com"),
                                   QDateTime::currentDateTimeUtc()));

        QCOMPARE(model.rowCount(), 0);
        QCOMPARE(model.anchorRow(), -1);
    }

    void changingFolderModelRefreshesConversation()
    {
        const auto seed = makeItem(2,
                                   QStringLiteral("Seed"),
                                   QStringLiteral("seed@example.com"),
                                   QStringLiteral("seed@example.com"),
                                   QStringLiteral("recipient@example.com"),
                                   QDateTime::currentDateTimeUtc());
        const auto first = makeItem(1,
                                    QStringLiteral("First"),
                                    QStringLiteral("first@example.com"),
                                    QStringLiteral("first@example.com"),
                                    QStringLiteral("recipient@example.com"),
                                    QDateTime::currentDateTimeUtc());
        const auto replacement = makeItem(4,
                                          QStringLiteral("Replacement"),
                                          QStringLiteral("replacement@example.com"),
                                          QStringLiteral("replacement@example.com"),
                                          QStringLiteral("recipient@example.com"),
                                          QDateTime::currentDateTimeUtc());

        MailPresentationModel firstFolder;
        MailPresentationModel secondFolder;

        TestConversationModel model;
        model.setItems({first, seed});
        const QAbstractItemModelTester modelTester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);
        QSignalSpy folderChanged(&model, &ConversationModel::folderModelChanged);
        QSignalSpy modelReset(&model, &QAbstractItemModel::modelReset);

        model.setFolderModel(&firstFolder);
        model.setSeedItem(seed);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.anchorRow(), 1);

        model.setItems({seed, replacement});
        model.setFolderModel(&secondFolder);
        QCOMPARE(folderChanged.count(), 2);
        QCOMPARE(modelReset.count(), 3);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.anchorRow(), 0);
        QCOMPARE(model.index(1, 0).data(ConversationModel::ItemIdRole).toLongLong(), 4);
    }
};

QTEST_MAIN(ConversationModelTest)

#include "conversationmodeltest.moc"
