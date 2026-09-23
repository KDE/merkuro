// SPDX-FileCopyrightText: 2026 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <Akonadi/Item>
#include <QObject>
#include <QTemporaryFile>
#include <QUrl>
#include <memory>
#include <qqmlregistration.h>

class QAbstractItemModel;
class QItemSelectionModel;

class ContactImportExport : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QAbstractItemModel *model MEMBER m_model)
    Q_PROPERTY(QItemSelectionModel *selectionModel MEMBER m_selectionModel)
    Q_PROPERTY(bool importInProgress READ importInProgress NOTIFY importInProgressChanged)

public:
    explicit ContactImportExport(QObject *parent = nullptr);

    [[nodiscard]] bool importInProgress() const;
    Q_INVOKABLE void importContacts(const QUrl &url, qint64 collectionId);
    Q_INVOKABLE void exportContacts(const QUrl &url);
    Q_INVOKABLE void exportContact(const QUrl &url, qint64 itemId);
    Q_INVOKABLE void prepareContactForSharing(qint64 itemId);

Q_SIGNALS:
    void importInProgressChanged();
    void importFinished(bool success, int count, const QString &errorMessage);
    void exportFinished(bool success, int count, const QString &errorMessage);
    void contactReadyToShare(const QUrl &url);

private:
    void setImportInProgress(bool inProgress);
    void finishImport();
    void writeContacts(const QUrl &url, const Akonadi::Item::List &items);

    QAbstractItemModel *m_model = nullptr;
    QItemSelectionModel *m_selectionModel = nullptr;
    bool m_importInProgress = false;
    int m_pendingCreates = 0;
    int m_importedCount = 0;
    bool m_importFailed = false;
    QString m_importError;
    Akonadi::Item::List m_itemsToImport;
    std::unique_ptr<QTemporaryFile> m_sharedContactFile;
};
