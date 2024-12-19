// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "mailmodel.h"

#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/MessageStatus>
#include <Akonadi/SelectionProxyModel>
#include <KFormat>
#include <KLocalizedString>
#include <KMime/Message>

MailModel::MailModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

QHash<int, QByteArray> MailModel::roleNames() const
{
    return {
        {TitleRole, QByteArrayLiteral("title")},
        {DateRole, QByteArrayLiteral("date")},
        {DateTimeRole, QByteArrayLiteral("datetime")},
        {SenderRole, QByteArrayLiteral("sender")},
        {FromRole, QByteArrayLiteral("from")},
        {ToRole, QByteArrayLiteral("to")},
        {StatusRole, QByteArrayLiteral("status")},
        {FavoriteRole, QByteArrayLiteral("favorite")},
        {TextColorRole, QByteArrayLiteral("textColor")},
        {BackgroundColorRole, QByteArrayLiteral("backgroudColor")},
        {ItemRole, QByteArrayLiteral("item")},
    };
}

QVariant MailModel::data(const QModelIndex &index, int role) const
{
    QVariant itemVariant = sourceModel()->data(mapToSource(index), Akonadi::EntityTreeModel::ItemRole);

    Akonadi::Item item = itemVariant.value<Akonadi::Item>();

    if (!item.hasPayload<KMime::Message::Ptr>()) {
        return {};
    }
    const KMime::Message::Ptr mail = item.payload<KMime::Message::Ptr>();

    // Static for speed reasons
    static const QString noSubject = i18nc("displayed as subject when the subject of a mail is empty", "No Subject");
    static const QString unknown(i18nc("displayed when a mail has unknown sender, receiver or date", "Unknown"));

    QString subject = mail->subject()->asUnicodeString();
    if (subject.isEmpty()) {
        subject = QLatin1Char('(') + noSubject + QLatin1Char(')');
    }

    MessageStatus stat;
    stat.setStatusFromFlags(item.flags());

    // NOTE: remember to update AkonadiBrowserSortModel::lessThan if you insert/move columns
    switch (role) {
    case TitleRole:
        if (mail->subject()) {
            return mail->subject()->asUnicodeString();
        } else {
            return noSubject;
        }
    case FromRole:
        if (mail->from()) {
            return mail->from()->asUnicodeString();
        } else {
            return QString();
        }
    case SenderRole:
        if (mail->sender()) {
            return mail->sender()->asUnicodeString();
        } else {
            return QString();
        }
    case ToRole:
        if (mail->to()) {
            return mail->to()->asUnicodeString();
        } else {
            return unknown;
        }
    case DateRole:
        if (mail->date()) {
            KFormat format;
            return format.formatRelativeDate(mail->date()->dateTime().date(), QLocale::LongFormat);
        } else {
            return QString();
        }
    case DateTimeRole:
        if (mail->date()) {
            return mail->date()->dateTime();
        } else {
            return QString();
        }
    case StatusRole:
        return QVariant::fromValue(stat);
    case ItemRole:
        return QVariant::fromValue(item);
    }

    return {};
}

Akonadi::Item MailModel::itemForRow(int row) const
{
    return data(index(row, 0), ItemRole).value<Akonadi::Item>();
}

void MailModel::updateMessageStatus(int row, MessageStatus messageStatus)
{
    Akonadi::Item item = itemForRow(row);
    item.setFlags(messageStatus.statusFlags());
    auto job = new Akonadi::ItemModifyJob(item, this);
    job->disableRevisionCheck();
    job->setIgnorePayload(true);

    Q_EMIT dataChanged(index(row, 0), index(row, 0), {StatusRole});
}

MessageStatus MailModel::copyMessageStatus(MessageStatus messageStatus)
{
    MessageStatus newStatus;
    newStatus.set(messageStatus);
    return messageStatus;
}

QString MailModel::searchString() const
{
    return m_searchString;
}

void MailModel::setSearchString(const QString &searchString)
{
    if (searchString == m_searchString) {
        return;
    }
    m_searchString = searchString;
    invalidateFilter();
    Q_EMIT searchStringChanged();
}

bool MailModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    Q_UNUSED(sourceParent)
    if (m_searchString.isEmpty()) {
        return true;
    }
    QVariant itemVariant = sourceModel()->index(sourceRow, 0).data(Akonadi::EntityTreeModel::ItemRole);

    Akonadi::Item item = itemVariant.value<Akonadi::Item>();

    if (!item.hasPayload<KMime::Message::Ptr>()) {
        return false;
    }
    const KMime::Message::Ptr mail = item.payload<KMime::Message::Ptr>();

    if (mail->subject() && mail->subject()->asUnicodeString().contains(m_searchString)) {
        return true;
    }
    if (mail->from() && mail->from()->asUnicodeString().contains(m_searchString)) {
        return true;
    }
    return false;
}

Akonadi::EntityTreeModel *MailModel::entryTreeModel() const
{
    return m_entityTreeModel;
}

void MailModel::setEntityTreeModel(Akonadi::EntityTreeModel *entityTreeModel)
{
    if (m_entityTreeModel == entityTreeModel) {
        return;
    }

    m_entityTreeModel = entityTreeModel;
    Q_EMIT entityTreeModelChanged();

    if (!m_entityTreeModel) {
        return;
    }
    setupModel();
}

QItemSelectionModel *MailModel::collectionSelectionModel() const
{
    return m_collectionSelectionModel;
}

void MailModel::setCollectionSelectionModel(QItemSelectionModel *collectionSelectionModel)
{
    if (m_collectionSelectionModel == collectionSelectionModel) {
        return;
    }

    m_collectionSelectionModel = collectionSelectionModel;
    Q_EMIT collectionSelectionModelChanged();

    if (!m_collectionSelectionModel) {
        return;
    }
    setupModel();

    connect(m_collectionSelectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
        Q_UNUSED(deselected)
        const auto indexes = selected.indexes();
        if (indexes.isEmpty()) {
            return;
        }
        QString name;
        QModelIndex index = indexes[0];
        while (index.isValid()) {
            if (name.isEmpty()) {
                name = index.data(Qt::DisplayRole).toString();
            } else {
                name = index.data(Qt::DisplayRole).toString() + QLatin1StringView(" / ") + name;
            }
            index = index.parent();
        }
        m_folderName = name;
        Q_EMIT folderNameChanged();
    });
}

void MailModel::setupModel()
{
    if (!m_collectionSelectionModel || !m_entityTreeModel) {
        return;
    }

    auto selectionModel = new Akonadi::SelectionProxyModel(m_collectionSelectionModel, this);
    selectionModel->setSourceModel(m_entityTreeModel);
    selectionModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    // Setup mail model
    auto folderFilterModel = new Akonadi::EntityMimeTypeFilterModel(this);
    folderFilterModel->setSourceModel(selectionModel);
    folderFilterModel->setHeaderGroup(Akonadi::EntityTreeModel::ItemListHeaders);
    folderFilterModel->addMimeTypeInclusionFilter(KMime::Message::mimeType());
    folderFilterModel->addMimeTypeExclusionFilter(Akonadi::Collection::mimeType());

    setSourceModel(folderFilterModel);
}

QString MailModel::folderName() const
{
    return m_folderName;
}

#include "moc_mailmodel.cpp"
